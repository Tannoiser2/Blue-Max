class_name Mondo
extends Node3D
## Il cielo di Francia in 3D: mappa fotografata con la griglia esagonale, aerei, effetti, telecamera.
## La telecamera si muove con mouse (sinistro: sposta, destro: ruota, rotella: zoom) e con il tocco
## (un dito: sposta, due dita: pizzica per lo zoom e ruota, due dita su e giù: inclinazione).

signal cella_toccata(c: Vector2i)
signal aereo_toccato(id: int)

const QUOTA_Y := [0.75, 1.25, 1.75, 2.25, 2.75]
const MODELLI := {"snipe": "camel", "pfalz_d12": "pfalz_d3", "ssw_d4": "ssw_d3"}
const SCALA_AEREO := 1.35

var R: Regole
var origine = Vector2(-2.75, -1.8)
var dim = Vector2(18.95, 23.3)
var mappa: MeshInstance3D
var mat_mappa: ShaderMaterial
var evid_img: Image
var evid_tex: ImageTexture
const EV_Q0 := -10
const EV_R0 := -2
const EV_W := 24
const EV_H := 18

var cam: Camera3D
var perno = Vector3.ZERO
var yaw = 0.0
var pitch = 58.0
var dist = 22.0
var perno_dest = Vector3.ZERO
var dist_dest = 22.0
var yaw_dest = 0.0
var pitch_dest = 58.0
var tocchi = {}
var trascina = ""
var ultimo_mouse = Vector2.ZERO
var spostato = 0.0

var nodi = {}        # id -> {radice, modello, colonna, anello, fumo, fuoco, elica}
var fantasma: Node3D
var segni: Node3D     # marcatori del percorso
var effetti: Node3D   # esplosioni, roghi, scintille (si tolgono con pulisci_effetti)
var overlay: Control  # etichette 2D sopra gli aerei (non ruotano con la telecamera)
var etichette = {}
var animazioni = 0
var luce: DirectionalLight3D

func _ready() -> void:
	var m: Dictionary = Dati.mappa
	origine = Vector2(m["origine"][0], m["origine"][1])
	dim = Vector2(m["larghezza"], m["altezza"])
	_ambiente()
	_mappa()
	cam = Camera3D.new()
	cam.fov = 45
	cam.far = 400
	add_child(cam)
	perno = Vector3(dim.x / 2, 0, dim.y / 2)
	perno_dest = perno
	segni = Node3D.new()
	add_child(segni)
	effetti = Node3D.new()
	add_child(effetti)
	_aggiorna_camera(true)

# --------------------------------------------------------------------------- ambiente
func _ambiente() -> void:
	var we = WorldEnvironment.new()
	var env = Environment.new()
	var sky = Sky.new()
	var ps = ProceduralSkyMaterial.new()
	ps.sky_top_color = Color("4f7db0")
	ps.sky_horizon_color = Color("c9d4dc")
	ps.ground_horizon_color = Color("c9d4dc")
	ps.ground_bottom_color = Color("7f9fc0")
	ps.sky_curve = 0.12
	ps.ground_curve = 0.08
	ps.sun_angle_max = 18
	ps.sky_energy_multiplier = 0.85
	ps.ground_energy_multiplier = 0.85
	sky.sky_material = ps
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color("c3cfd9")
	env.fog_density = 0.004
	env.fog_sky_affect = 0.3
	we.environment = env
	add_child(we)
	luce = DirectionalLight3D.new()
	luce.rotation_degrees = Vector3(-52, -35, 0)
	luce.light_energy = 0.75
	luce.light_color = Color("fff1dc")
	luce.shadow_enabled = true
	luce.shadow_opacity = 0.55
	luce.directional_shadow_max_distance = 80
	add_child(luce)

const SHADER_MAPPA := """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D evid : filter_nearest;
uniform vec2 origine;
uniform vec2 dim;
uniform float griglia = 0.45;
uniform vec2 ev0;
uniform vec2 evdim;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
vec3 cube_round(vec3 c) {
	vec3 r = round(c);
	vec3 d = abs(r - c);
	if (d.x > d.y && d.x > d.z) r.x = -r.y - r.z; else if (d.y > d.z) r.y = -r.x - r.z; else r.z = -r.x - r.y;
	return r;
}
void fragment() {
	vec2 uv = wp.xz / dim;
	vec3 col = texture(tex, uv).rgb;
	vec2 p = wp.xz + origine;
	float q = 0.57735 * p.x - p.y / 3.0;
	float r = 2.0 / 3.0 * p.y;
	vec3 c = cube_round(vec3(q, r, -q - r));
	vec2 centro = vec2(1.7320508 * (c.x + c.y * 0.5), 1.5 * c.y);
	vec2 v = p - centro;
	float e = max(abs(v.x), max(abs(dot(v, vec2(0.5, 0.8660254))), abs(dot(v, vec2(-0.5, 0.8660254)))));
	float linea = smoothstep(0.80, 0.855, e);
	col = mix(col, vec3(0.12, 0.09, 0.06), linea * griglia);
	vec2 ec = (c.xy - ev0 + 0.5) / evdim;
	vec4 h = texture(evid, ec);
	if (h.a > 0.0) {
		float bordo = smoothstep(0.66, 0.84, e);
		col = mix(col, h.rgb, h.a * (0.28 + 0.6 * bordo));
	}
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}
"""

func _mappa() -> void:
	var pm = PlaneMesh.new()
	pm.size = dim
	mappa = MeshInstance3D.new()
	mappa.mesh = pm
	mappa.position = Vector3(dim.x / 2, 0, dim.y / 2)
	var sh = Shader.new()
	sh.code = SHADER_MAPPA
	mat_mappa = ShaderMaterial.new()
	mat_mappa.shader = sh
	mat_mappa.set_shader_parameter("tex", load(Dati.mappa["immagine"]))
	mat_mappa.set_shader_parameter("origine", origine)
	mat_mappa.set_shader_parameter("dim", dim)
	evid_img = Image.create(EV_W, EV_H, false, Image.FORMAT_RGBA8)
	evid_tex = ImageTexture.create_from_image(evid_img)
	mat_mappa.set_shader_parameter("evid", evid_tex)
	mat_mappa.set_shader_parameter("ev0", Vector2(EV_Q0, EV_R0))
	mat_mappa.set_shader_parameter("evdim", Vector2(EV_W, EV_H))
	mappa.material_override = mat_mappa
	mappa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mappa)
	# bordo di cartone sotto la mappa
	var base = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(dim.x + 0.6, 0.25, dim.y + 0.6)
	base.mesh = bm
	base.position = Vector3(dim.x / 2, -0.14, dim.y / 2)
	var mb = StandardMaterial3D.new()
	mb.albedo_color = Color("3b2f22")
	mb.roughness = 1.0
	base.material_override = mb
	add_child(base)


func griglia_visibile(v: bool) -> void:
	mat_mappa.set_shader_parameter("griglia", 0.45 if v else 0.0)

func _nuvole() -> void:
	# cumuli tutto intorno: sopra, ai lati e sotto la mappa, che galleggia nel cielo
	var rn := RandomNumberGenerator.new()
	rn.seed = 77
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.97, 0.96, 0.93, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat.roughness = 1.0
	var centro := Vector3(dim.x / 2, 0, dim.y / 2)
	for i in 46:
		var g := Node3D.new()
		var ang := rn.randf_range(0, TAU)
		var r := rn.randf_range(18, 70)
		var y := rn.randf_range(-22, 9)
		if i < 14:
			# sotto la mappa: nuvole basse che si vedono dai bordi
			r = rn.randf_range(4, 26)
			y = rn.randf_range(-14, -5)
		g.position = centro + Vector3(cos(ang) * r, y, sin(ang) * r)
		var grande := rn.randf_range(1.0, 2.6)
		for k in rn.randi_range(5, 9):
			var sfera := MeshInstance3D.new()
			var sm := SphereMesh.new()
			var rr := rn.randf_range(1.3, 2.8) * grande
			sm.radius = rr
			sm.height = rr * 1.2
			sm.radial_segments = 12
			sm.rings = 6
			sfera.mesh = sm
			sfera.material_override = mat
			sfera.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			sfera.position = Vector3(rn.randf_range(-3.0, 3.0), rn.randf_range(-0.5, 0.9), rn.randf_range(-2.0, 2.0)) * grande
			g.add_child(sfera)
		add_child(g)

# --------------------------------------------------------------------------- coordinate
func mondo_da_cella(c: Vector2i) -> Vector3:
	var p = Hex.centro(c) - origine
	return Vector3(p.x, 0, p.y)

func cella_da_mondo(p: Vector3) -> Vector2i:
	var v = Vector2(p.x, p.z) + origine
	var q = 0.57735 * v.x - v.y / 3.0
	var r = 2.0 / 3.0 * v.y
	var x = q
	var z = r
	var y = -x - z
	var rx = roundf(x)
	var ry = roundf(y)
	var rz = roundf(z)
	var dx = absf(rx - x)
	var dy = absf(ry - y)
	var dz = absf(rz - z)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector2i(int(rx), int(rz))

func yaw_da_prua(prua: int) -> float:
	return deg_to_rad(90.0 - 60.0 * prua)

func altezza(quota: int) -> float:
	return QUOTA_Y[clampi(quota, 0, 4)]

# --------------------------------------------------------------------------- evidenziazioni
func pulisci_evid() -> void:
	evid_img.fill(Color(0, 0, 0, 0))
	evid_base = null
	evid_tex.update(evid_img)

## Linea di tiro provvisoria sopra le evidenziazioni già presenti (si ridisegna a ogni manovra provata)
var evid_base: Image = null
func linea_tiro(celle: Array) -> void:
	if evid_base == null:
		evid_base = evid_img.duplicate()
	else:
		evid_img.copy_from(evid_base)
	evidenzia(celle, Color(1, 0.3, 0.2, 0.55))

func evidenzia(celle: Array, colore: Color, pulisci := false) -> void:
	if pulisci:
		evid_img.fill(Color(0, 0, 0, 0))
		evid_base = null
	for c in celle:
		var x: int = int(c.x) - EV_Q0
		var y: int = int(c.y) - EV_R0
		if x >= 0 and x < EV_W and y >= 0 and y < EV_H:
			evid_img.set_pixel(x, y, colore)
	evid_tex.update(evid_img)

# --------------------------------------------------------------------------- aerei
func _modello(tipo: String) -> Node3D:
	var nome: String = Dati.aerei.get(tipo, {}).get("modello", tipo)
	var p = "res://assets/modelli/%s.glb" % nome
	var sc = load(p)
	if sc == null:
		var mi = MeshInstance3D.new()
		var b = BoxMesh.new()
		b.size = Vector3(1, 0.1, 0.6)
		mi.mesh = b
		return mi
	var n: Node3D = sc.instantiate()
	return n

var nodo_nuvole: Node3D
const SHADER_NUVOLA := """
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_back;
uniform vec4 colore : source_color = vec4(1.0, 0.99, 0.97, 1.0);
uniform float densita = 0.55;
varying vec3 n_vista;
void vertex() { n_vista = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz); }
void fragment() {
	// bordi sfumati: più trasparente dove la superficie è di taglio
	float f = clamp(dot(normalize(n_vista), vec3(0.0, 0.0, 1.0)), 0.0, 1.0);
	float a = pow(f, 1.6) * densita;
	float luce = 0.82 + 0.18 * n_vista.y;
	ALBEDO = colore.rgb * luce;
	ALPHA = a;
}
"""

## Le nuvole della partita (regola della casa): grappoli di sfere morbide alla quota della nuvola
func crea_nuvole() -> void:
	if nodo_nuvole:
		nodo_nuvole.queue_free()
	nodo_nuvole = Node3D.new()
	add_child(nodo_nuvole)
	if R == null:
		return
	var sh := Shader.new()
	sh.code = SHADER_NUVOLA
	var rn := RandomNumberGenerator.new()
	rn.seed = 4242
	for nv in R.S.get("nuvole", []):
		var mat := ShaderMaterial.new()
		mat.shader = sh
		mat.set_shader_parameter("densita", 0.42)
		var h := altezza(int(nv["quota"]))
		# contorno dell'esagono alla quota della nuvola e la sua ombra sulla mappa
		var bordo := _contorni_esagoni(nv["celle"], h, 0.045, Color(1, 1, 1, 0.85))
		nodo_nuvole.add_child(bordo)
		nodo_nuvole.add_child(_contorni_esagoni(nv["celle"], 0.02, 0.035, Color(0.1, 0.16, 0.3, 0.6)))
		nodo_nuvole.add_child(_contorni_esagoni(nv["celle"], 0.02, 0.0, Color(0.1, 0.16, 0.3, 0.16), true))
		for c in nv["celle"]:
			var base := mondo_da_cella(Vector2i(int(c[0]), int(c[1])))
			for k in 6:
				var sf := MeshInstance3D.new()
				var sm := SphereMesh.new()
				var r := rn.randf_range(0.4, 0.62)
				sm.radius = r
				sm.height = r * 1.3
				sm.radial_segments = 16
				sm.rings = 8
				sf.mesh = sm
				sf.material_override = mat
				sf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var ang := rn.randf() * TAU
				var dist := rn.randf_range(0.0, 0.38)
				sf.position = base + Vector3(cos(ang) * dist, h + rn.randf_range(-0.15, 0.12), sin(ang) * dist)
				nodo_nuvole.add_child(sf)

## Bordi netti degli esagoni (nastri sottili) per capire dove sta una nuvola; con ombra=true anche il riempimento
func _contorni_esagoni(celle: Array, h: float, largo: float, colore: Color, ombra := false) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for c in celle:
		var b := mondo_da_cella(Vector2i(int(c[0]), int(c[1])))
		var ang = []
		for k in 7:
			var t := deg_to_rad(30.0 + 60.0 * k)
			ang.append(Vector3(cos(t), 0, sin(t)))
		for k in (0 if ombra else 6):
			var e1: Vector3 = ang[k] * 0.97
			var e2: Vector3 = ang[k + 1] * 0.97
			var i1: Vector3 = ang[k] * (0.97 - largo * 2.0)
			var i2: Vector3 = ang[k + 1] * (0.97 - largo * 2.0)
			for v in [e1, e2, i2, e1, i2, i1]:
				st.add_vertex(b + v + Vector3(0, h, 0))
		if ombra:
			for k in 6:
				for v in [Vector3.ZERO, ang[k + 1] * 0.9, ang[k] * 0.9]:
					st.add_vertex(b + v + Vector3(0, h - 0.005, 0))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = colore
	m.no_depth_test = false
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

func crea_aerei() -> void:
	crea_nuvole()
	for k in nodi:
		for parte in ["radice", "colonna", "anello"]:
			nodi[k][parte].queue_free()
	nodi.clear()
	for a in R.S["aerei"]:
		_crea_aereo(a)
	aggiorna_tutti()

func _crea_aereo(a: Dictionary) -> void:
	var rad = Node3D.new()
	add_child(rad)
	var asse = Node3D.new()   # rollio e beccheggio delle animazioni
	rad.add_child(asse)
	var mod = _modello(a["tipo"])
	mod.scale = Vector3.ONE * SCALA_AEREO
	asse.add_child(mod)
	var col = Tema.colore_lato(a["lato"])
	# colonna della quota: filo sottile fino all'esagono
	var colonna = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.012
	cm.bottom_radius = 0.012
	cm.height = 1.0
	cm.radial_segments = 6
	colonna.mesh = cm
	var mc = StandardMaterial3D.new()
	mc.albedo_color = Color(col.r, col.g, col.b, 0.75)
	mc.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mc.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	colonna.material_override = mc
	colonna.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(colonna)
	# anello colorato sulla mappa e freccia della prua
	var anello = MeshInstance3D.new()
	var tm = TorusMesh.new()
	tm.inner_radius = 0.62
	tm.outer_radius = 0.72
	tm.rings = 24
	tm.ring_segments = 6
	anello.mesh = tm
	var ma = StandardMaterial3D.new()
	ma.albedo_color = col
	ma.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	anello.material_override = ma
	anello.scale = Vector3(1, 0.15, 1)
	anello.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(anello)
	var freccia = MeshInstance3D.new()
	var pr = PrismMesh.new()
	pr.size = Vector3(0.36, 0.3, 0.03)
	freccia.mesh = pr
	freccia.material_override = ma
	freccia.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	anello.add_child(freccia)
	freccia.rotation_degrees = Vector3(90, 0, 0)
	freccia.position = Vector3(0, 0.2, 0.86)
	freccia.scale = Vector3(1, 1, 1.0 / 0.15)
	nodi[a["id"]] = {"radice": rad, "asse": asse, "modello": mod, "colonna": colonna, "anello": anello, "fumo": null, "fuoco": null,
		"stato": "", "cella": Vector2i(a["q"], a["r"]), "prua": a["prua"], "quota": a["quota"]}

func _offset(a: Dictionary) -> Vector3:
	# più aerei nello stesso esagono: piccoli spostamenti per non sovrapporli
	var c = R.pos(a)
	var stessi = []
	for b in R.S["aerei"]:
		if R.in_gioco(b) and R.pos(b) == c and absi(int(b["quota"]) - int(a["quota"])) <= 0:
			stessi.append(b["id"])
	if stessi.size() <= 1:
		return Vector3.ZERO
	var i = stessi.find(a["id"])
	var ang = TAU * i / stessi.size()
	return Vector3(cos(ang), 0, sin(ang)) * 0.34

func aggiorna_tutti() -> void:
	for a in R.S["aerei"]:
		aggiorna(a)

func aggiorna(a: Dictionary) -> void:
	var n: Dictionary = nodi.get(a["id"], {})
	if n.is_empty():
		return
	var vivo = R.in_gioco(a)
	var rad: Node3D = n["radice"]
	if a["stato"] in ["fuggito", "catturato", "atterrato"]:
		rad.visible = false
		n["colonna"].visible = false
		n["anello"].visible = false
		return
	if a["stato"] == "abbattuto":
		n["colonna"].visible = false
		n["anello"].visible = false
		if n["stato"] != "abbattuto":
			rad.visible = false
		n["stato"] = "abbattuto"
		return
	rad.visible = true
	var base = mondo_da_cella(R.pos(a)) + _offset(a)
	var h = altezza(a["quota"])
	rad.position = base + Vector3(0, h, 0)
	rad.rotation = Vector3(0, yaw_da_prua(a["prua"]), 0)
	# l'aereo resta inclinato come ha finito l'ultima manovra
	n["asse"].rotation = Vector3(float(n.get("becc", 0.0)), 0, float(n.get("rollio", 0.0)))
	if a["stato"] == "vite":
		n["asse"].rotation_degrees = Vector3(35, 0, 25)
	n["colonna"].visible = vivo
	n["colonna"].position = base + Vector3(0, h / 2, 0)
	n["colonna"].scale = Vector3(1, h, 1)
	n["anello"].visible = vivo
	n["anello"].position = mondo_da_cella(R.pos(a)) + Vector3(0, 0.03, 0)
	n["anello"].rotation = Vector3(0, yaw_da_prua(a["prua"]), 0)
	n["cella"] = R.pos(a)
	n["prua"] = a["prua"]
	n["quota"] = a["quota"]
	n["stato"] = a["stato"]
	_effetti_stato(a)

func _effetti_stato(a: Dictionary) -> void:
	var n: Dictionary = nodi[a["id"]]
	var vuole_fumo: bool = a["fumo"] or a["fuoco"] or a["stato"] == "vite"
	if vuole_fumo and n["fumo"] == null:
		n["fumo"] = Effetti.scia_fumo(Color(0.18, 0.17, 0.16, 0.8) if a["fuoco"] else Color(0.45, 0.44, 0.42, 0.7))
		n["asse"].add_child(n["fumo"])
		n["fumo"].position = Vector3(0, 0.02, -0.25)
	elif not vuole_fumo and n["fumo"] != null:
		n["fumo"].emitting = false
		var f: Node = n["fumo"]
		get_tree().create_timer(3.0).timeout.connect(f.queue_free)
		n["fumo"] = null
	if a["fuoco"] and n["fuoco"] == null:
		n["fuoco"] = Effetti.fiamme()
		n["asse"].add_child(n["fuoco"])
		n["fuoco"].position = Vector3(0, 0.05, 0.18)
	elif not a["fuoco"] and n["fuoco"] != null:
		n["fuoco"].queue_free()
		n["fuoco"] = null

func pulisci_effetti() -> void:
	for c in effetti.get_children():
		c.queue_free()

func posizione_aereo(id: int) -> Vector3:
	var n: Dictionary = nodi.get(id, {})
	if n.is_empty():
		return Vector3.ZERO
	return n["radice"].global_position

# --------------------------------------------------------------------------- animazioni del movimento
## Muove un aereo lungo il percorso della manovra (passi esagono per esagono)
func anima_manovra(a: Dictionary, ev: Dictionary, durata := 1.8, lineare := false) -> void:
	var n: Dictionary = nodi.get(a["id"], {})
	if n.is_empty():
		return
	animazioni += 1
	var per: Array = ev["percorso"]
	var rad: Node3D = n["radice"]
	var asse: Node3D = n["asse"]
	var h0 = altezza(int(ev["quota_da"]))
	var h1 = altezza(int(ev["quota_a"]))
	var punti = []
	for p in per:
		punti.append(mondo_da_cella(Vector2i(int(p["q"]), int(p["r"]))))
	var y0 = yaw_da_prua(int(per[0]["prua"]))
	var y1 = yaw_da_prua(int(per[-1]["prua"]))
	var dy = wrapf(y1 - y0, -PI, PI)
	var cod: String = ev["codice"]
	var num: int = int(Dati.codice(cod)["n"]) if cod != "" else 2
	if num in [27, 24, 29, 11] and absf(dy) < 0.01:
		dy = PI
	if num in [27, 29, 11]:
		dy = PI if dy > 0 else -PI
	# percorso morbido: curva fra i centri degli esagoni
	var curva = Curve3D.new()
	var dedup = []
	for p in punti:
		if dedup.is_empty() or (dedup[-1] as Vector3).distance_to(p) > 0.01:
			dedup.append(p)
	if dedup.size() == 1:
		dedup.append(dedup[0])
	for i in dedup.size():
		var p: Vector3 = dedup[i]
		var tan = Vector3.ZERO
		if i > 0 and i < dedup.size() - 1:
			tan = ((dedup[i + 1] as Vector3) - (dedup[i - 1] as Vector3)) * 0.25
		elif i == 0 and dedup.size() > 1:
			var dir0 = Vector3(sin(y0), 0, cos(y0))
			tan = dir0 * 0.5
		elif i == dedup.size() - 1 and i > 0 and absf(dy) < 1.1 and not (num in [10, 17]):
			# arrivo già girato verso la prua finale (virate di 60 gradi)
			var corda: Vector3 = (p - (dedup[i - 1] as Vector3))
			var fin = Vector3(sin(y0 + dy), 0, cos(y0 + dy)) * corda.length()
			tan = (corda + fin) * 0.25
		curva.add_point(p, -tan, tan)
	var esito: String = ev.get("esito", "")
	var L = curva.get_baked_length()
	var in_vite = num == 0 or esito == "vite" or a["stato"] == "vite"
	# il muso segue la traiettoria: parte con la prua iniziale, segue la curva, chiude con la prua finale
	var segue = L > 0.05 and not (num in [10, 17, 27, 28, 29, 30, 34, 35]) and not in_vite
	var tangente = func(e: float) -> float:
		var e1 = clampf(e - 0.03, 0.0, 1.0)
		var e2 = clampf(e + 0.03, 0.0, 1.0)
		var d: Vector3 = curva.sample_baked(e2 * L) - curva.sample_baked(e1 * L)
		if d.length() < 0.0001:
			return 0.0
		return wrapf(atan2(d.x, d.z) - y0, -PI, PI)
	if segue and absf(absf(dy) - PI) < 0.05:
		# inversione: il verso di rotazione è quello in cui sta già curvando
		var fine = tangente.call(0.9)
		dy = PI if fine >= 0 else -PI
	var lato = 0.0
	if num in [10, 17]:
		lato = signf(tangente.call(0.5))
	var rotta = func(e: float) -> float:
		if not segue:
			return dy * e
		var off = lerpf(0.0, tangente.call(e), smoothstep(0.0, 0.3, e))
		return lerpf(off, dy, smoothstep(0.55, 1.0, e))
	# assetto di partenza (quello lasciato dalla manovra precedente) e assetto d'arrivo
	var r0 := float(n.get("rollio", 0.0))
	var b0 := float(n.get("becc", 0.0))
	var acro: bool = num >= 27 or in_vite
	var r1 := 0.0
	if not acro:
		r1 = -clampf(dy * 0.5, -0.75, 0.75)
		if lato != 0.0:
			r1 = lato * 0.25
	var b1 := 0.0 if acro else -atan((h1 - h0) * 1.2) * 0.35
	n["rollio"] = r1
	n["becc"] = b1
	var tw = create_tween()
	var fun = func(t: float):
		var e = t if lineare else t * t * (3.0 - 2.0 * t)
		var pos = curva.sample_baked(e * L) if L > 0.01 else dedup[0]
		var h = lerpf(h0, h1, e)
		var giro = y0 + rotta.call(e)
		var becc = 0.0
		# inclinazione delle ali secondo quanto sta virando in quel momento
		var vel_virata = (rotta.call(minf(e + 0.04, 1.0)) - rotta.call(maxf(e - 0.04, 0.0))) / 0.08
		var rollio = -clampf(vel_virata * 0.45, -1.1, 1.1)
		if not segue:
			rollio = -clampf(dy * 0.9, -1.1, 1.1) * sin(PI * e)
		if lato != 0.0:
			# spostamento laterale: il muso resta avanti, le ali si inclinano verso il lato
			rollio = lato * 0.55 * sin(PI * e)
		if num in [29, 30]:
			# Immelmann: mezzo giro della morte e mezzo tonneau
			becc = -PI * smoothstep(0.0, 0.7, e)
			rollio = PI * smoothstep(0.55, 1.0, e)
			h += sin(PI * e) * 0.6
			giro = y0 + (dy - PI) * e
		elif num in [34, 35]:
			rollio = TAU * e * (1 if num == 34 else -1)
		elif num in [27, 28, 32, 33]:
			becc = -sin(PI * e) * 1.2
			h += sin(PI * e) * 0.4
		elif in_vite:
			giro = y0 + TAU * 1.5 * e
			becc = 0.7
			rollio = 0.5
		var dq = h1 - h0
		becc += -atan(dq * 1.2) * sin(PI * e)
		var sm := smoothstep(0.0, 1.0, e)
		rollio += lerpf(r0, r1, sm)
		becc += lerpf(b0, b1, sm)
		if not acro:
			rollio = clampf(rollio, -1.3, 1.3)
		if not is_instance_valid(rad):
			return
		rad.position = pos + Vector3(0, h, 0)
		rad.rotation = Vector3(0, giro, 0)
		asse.rotation = Vector3(becc, 0, rollio)
		var col: MeshInstance3D = n["colonna"]
		col.position = pos + Vector3(0, h / 2, 0)
		col.scale = Vector3(1, h, 1)
	tw.tween_method(fun, 0.0, 1.0, durata)
	n["anello"].visible = false
	Suoni.motore(cod, h1 - h0)
	await tw.finished
	animazioni -= 1

func aspetta_animazioni() -> void:
	while animazioni > 0:
		await get_tree().process_frame

# --------------------------------------------------------------------------- combattimento
func spara(da: int, a: int, arma: String, raffica: String, colpito: bool) -> void:
	var pa := posizione_aereo(da)
	var pb := posizione_aereo(a)
	var n: int = {"corta": 5, "media": 10, "lunga": 16}.get(raffica, 8)
	var dir := (pb - pa).normalized()
	var origine_colpi := pa + dir * 0.55 + Vector3(0, 0.1, 0)
	if arma == "osservatore":
		origine_colpi = pa - dir * 0.1 + Vector3(0, 0.18, 0)
	Suoni.suona("raffica_" + raffica)
	var lampo := Effetti.lampo_bocca()
	effetti.add_child(lampo)
	lampo.global_position = origine_colpi
	get_tree().create_timer(0.3 + n * 0.08).timeout.connect(lampo.queue_free)
	for i in n:
		var t := Effetti.traccia()
		effetti.add_child(t)
		var disp := Vector3(randf_range(-0.15, 0.15), randf_range(-0.1, 0.1), randf_range(-0.15, 0.15))
		if not colpito:
			disp = disp * 3.0 + Vector3(randf_range(-0.5, 0.5), randf_range(0.2, 0.5), randf_range(-0.5, 0.5))
		var dest := pb + disp
		# la traccia prosegue oltre il bersaglio se manca
		if not colpito:
			dest = origine_colpi + (dest - origine_colpi) * 1.6
		t.look_at_from_position(origine_colpi, dest, Vector3.UP)
		t.visible = false
		var tw := create_tween()
		tw.tween_interval(i * 0.08)
		tw.tween_callback(func(): t.visible = true)
		tw.tween_property(t, "global_position", dest, 0.32)
		tw.tween_callback(t.queue_free)
	await get_tree().create_timer(0.32 + n * 0.08).timeout
	if colpito:
		var sc := Effetti.scintille()
		effetti.add_child(sc)
		sc.global_position = pb
		Suoni.suona("colpito", -4.0)
		get_tree().create_timer(1.5).timeout.connect(sc.queue_free)

func esplosione(id: int) -> void:
	var n: Dictionary = nodi.get(id, {})
	if n.is_empty():
		return
	var p = posizione_aereo(id)
	var e = Effetti.esplosione()
	effetti.add_child(e)
	Suoni.suona("esplosione")
	e.global_position = p
	get_tree().create_timer(4.0).timeout.connect(e.queue_free)
	await precipita(id)

## L'aereo abbattuto cade a vite fino a terra e brucia
func precipita(id: int) -> void:
	var n: Dictionary = nodi.get(id, {})
	if n.is_empty():
		return
	var rad: Node3D = n["radice"]
	rad.visible = true
	if n["fumo"] == null:
		n["fumo"] = Effetti.scia_fumo(Color(0.12, 0.11, 0.1, 0.85))
		n["asse"].add_child(n["fumo"])
	var p0 = rad.position
	var y0 = rad.rotation.y
	var tw = create_tween()
	animazioni += 1
	tw.tween_method(func(t: float):
		rad.position = p0 + Vector3(sin(t * 9.0) * 0.3 * t, -p0.y * t * t + 0.08 * t, cos(t * 9.0) * 0.3 * t)
		rad.rotation = Vector3(0, y0 + t * 12.0, 0)
		n["asse"].rotation = Vector3(1.0 * t, 0, 0.8), 0.0, 1.0, 2.4)
	await tw.finished
	var f = Effetti.rogo()
	effetti.add_child(f)
	f.global_position = Vector3(rad.position.x, 0.05, rad.position.z)
	rad.visible = false
	n["colonna"].visible = false
	n["anello"].visible = false
	animazioni -= 1

# --------------------------------------------------------------------------- anteprime
func pulisci_segni() -> void:
	for c in segni.get_children():
		c.queue_free()
	if fantasma:
		fantasma.queue_free()
		fantasma = null

## Mostra dove porta una manovra: esagoni del percorso e un aereo fantasma alla fine
func anteprima(a: Dictionary, codice: String, dq: int) -> void:
	pulisci_segni()
	var per = R.percorso(a, codice)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.85, 0.3, 0.85)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var h0 = altezza(a["quota"])
	var h1 = altezza(clampi(int(a["quota"]) + dq, 0, 4))
	for i in range(1, per.size()):
		var p: Dictionary = per[i]
		var s = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = 0.08
		sm.height = 0.16
		s.mesh = sm
		s.material_override = mat
		var t = float(i) / maxf(1.0, per.size() - 1)
		s.position = mondo_da_cella(Vector2i(int(p["q"]), int(p["r"]))) + Vector3(0, lerpf(h0, h1, t), 0)
		segni.add_child(s)
	var fin: Dictionary = per[-1]
	fantasma = Node3D.new()
	var mod = _modello(a["tipo"])
	mod.scale = Vector3.ONE * SCALA_AEREO
	fantasma.add_child(mod)
	add_child(fantasma)
	_trasparente(mod, 0.45)
	fantasma.position = mondo_da_cella(Vector2i(int(fin["q"]), int(fin["r"]))) + Vector3(0, h1, 0)
	fantasma.rotation = Vector3(0, yaw_da_prua(int(fin["prua"])), 0)
	evidenzia([Vector2i(int(fin["q"]), int(fin["r"]))], Color(1, 0.8, 0.2, 0.9))

func _trasparente(n: Node, alfa: float) -> void:
	if n is MeshInstance3D:
		var mi = n as MeshInstance3D
		var m = StandardMaterial3D.new()
		m.albedo_color = Color(1, 0.95, 0.75, alfa)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_trasparente(c, alfa)

# --------------------------------------------------------------------------- telecamera e input
func centra_su(p: Vector3, d := -1.0) -> void:
	perno_dest = Vector3(p.x, 0, p.z)
	if d > 0:
		dist_dest = d

func vista_alto() -> void:
	pitch_dest = 89.0
	yaw_dest = 0.0
	dist_dest = 30.0
	perno_dest = Vector3(dim.x / 2, 0, dim.y / 2)

func vista_3d() -> void:
	pitch_dest = 50.0
	dist_dest = 20.0

func _process(dt: float) -> void:
	var k = 1.0 - exp(-dt * 8.0)
	perno = perno.lerp(perno_dest, k)
	dist = lerpf(dist, dist_dest, k)
	yaw = lerp_angle(deg_to_rad(yaw), deg_to_rad(yaw_dest), k) * 180.0 / PI
	pitch = lerpf(pitch, pitch_dest, k)
	_aggiorna_camera(false)
	_aggiorna_etichette()

func _aggiorna_camera(subito: bool) -> void:
	if subito:
		perno = perno_dest
		dist = dist_dest
		yaw = yaw_dest
		pitch = pitch_dest
	var p = deg_to_rad(pitch)
	var y = deg_to_rad(yaw)
	var off = Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * dist
	cam.position = perno + off
	if pitch > 88.5:
		cam.look_at_from_position(cam.position, perno, Vector3(-sin(y), 0, -cos(y)))
	else:
		cam.look_at(perno, Vector3.UP)

func _limita() -> void:
	perno_dest.x = clampf(perno_dest.x, -4, dim.x + 4)
	perno_dest.z = clampf(perno_dest.z, -4, dim.y + 4)
	dist_dest = clampf(dist_dest, 4.0, 45.0)
	pitch_dest = clampf(pitch_dest, -10.0, 89.0)

func _sposta_schermo(d: Vector2) -> void:
	var y = deg_to_rad(yaw)
	var destra = Vector3(cos(y), 0, -sin(y))
	var avanti = Vector3(-sin(y), 0, -cos(y))
	var f = dist * 0.0016
	perno_dest += (-destra * d.x + avanti * d.y) * f
	_limita()

func gestisci_input(ev: InputEvent) -> bool:
	# il mouse finto generato dal tocco (iPad) serve ai bottoni, non alla telecamera: il tocco è già gestito qui
	if (ev is InputEventMouseButton or ev is InputEventMouseMotion) and ev.device == InputEvent.DEVICE_ID_EMULATION:
		return false
	if ev is InputEventScreenTouch:
		if ev.pressed:
			tocchi[ev.index] = ev.position
			spostato = 0.0
		else:
			if tocchi.size() == 1 and spostato < 12.0:
				_tocco(ev.position)
			tocchi.erase(ev.index)
		return true
	if ev is InputEventScreenDrag:
		var prima: Vector2 = tocchi.get(ev.index, ev.position)
		tocchi[ev.index] = ev.position
		spostato += ev.relative.length()
		if tocchi.size() == 1:
			_sposta_schermo(ev.relative)
		elif tocchi.size() >= 2:
			var k: Array = tocchi.keys()
			var altro: Vector2 = tocchi[k[0]] if k[0] != ev.index else tocchi[k[1]]
			var d0 = prima.distance_to(altro)
			var d1 = (ev.position as Vector2).distance_to(altro)
			if d0 > 1.0:
				dist_dest *= d0 / maxf(d1, 1.0)
			var a0 = (prima - altro).angle()
			var a1 = ((ev.position as Vector2) - altro).angle()
			yaw_dest += rad_to_deg(wrapf(a1 - a0, -PI, PI))
			pitch_dest += ev.relative.y * 0.12
			_limita()
		return true
	if ev is InputEventMagnifyGesture:
		dist_dest /= ev.factor
		_limita()
		return true
	if ev is InputEventPanGesture:
		_sposta_schermo(-ev.delta * 6.0)
		return true
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed:
			dist_dest *= 0.9
			_limita()
			return true
		if ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed:
			dist_dest *= 1.1
			_limita()
			return true
		if ev.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			if ev.pressed:
				trascina = "sposta" if ev.button_index == MOUSE_BUTTON_LEFT else "ruota"
				ultimo_mouse = ev.position
				spostato = 0.0
			else:
				if ev.button_index == MOUSE_BUTTON_LEFT and spostato < 6.0:
					_tocco(ev.position)
				trascina = ""
			return true
	if ev is InputEventMouseMotion and trascina != "":
		var d: Vector2 = ev.position - ultimo_mouse
		ultimo_mouse = ev.position
		spostato += d.length()
		if trascina == "sposta":
			_sposta_schermo(d)
		else:
			yaw_dest -= d.x * 0.3
			pitch_dest += d.y * 0.2
			_limita()
		return true
	return false

func _tocco(p: Vector2) -> void:
	# prima gli aerei (proiettati sullo schermo), poi la mappa
	var migliore = -1
	var dmin = 46.0
	for id in nodi:
		var n: Dictionary = nodi[id]
		if not n["radice"].visible:
			continue
		var wp: Vector3 = n["radice"].global_position
		if cam.is_position_behind(wp):
			continue
		var sp = cam.unproject_position(wp)
		var d = sp.distance_to(p)
		if d < dmin:
			dmin = d
			migliore = id
	if migliore >= 0:
		aereo_toccato.emit(migliore)
		return
	var o = cam.project_ray_origin(p)
	var dir = cam.project_ray_normal(p)
	if absf(dir.y) > 0.001:
		var t = -o.y / dir.y
		if t > 0:
			cella_toccata.emit(cella_da_mondo(o + dir * t))

# --------------------------------------------------------------------------- etichette 2D sopra gli aerei
func imposta_overlay(c: Control) -> void:
	overlay = c

func _aggiorna_etichette() -> void:
	if overlay == null or R == null:
		return
	for a in R.S["aerei"]:
		var id: int = a["id"]
		var l: Label = etichette.get(id)
		if l == null:
			l = Label.new()
			l.add_theme_font_override("font", Tema.font("grassetto"))
			l.add_theme_font_size_override("font_size", 17)
			l.add_theme_color_override("font_color", Color.WHITE)
			l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
			l.add_theme_constant_override("outline_size", 6)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay.add_child(l)
			etichette[id] = l
		var n: Dictionary = nodi.get(id, {})
		var vis = not n.is_empty() and n["radice"].visible and R.in_gioco(a)
		if vis:
			var wp: Vector3 = n["radice"].global_position + Vector3(0, 0.32, 0)
			if cam.is_position_behind(wp):
				vis = false
			else:
				var sp = cam.unproject_position(wp)
				l.text = "%s  %s%s" % [_breve(a), Dati.QUOTE_BREVI[int(a["quota"])], "  in nuvola" if R.in_nuvola(a) else ""]
				l.position = sp - Vector2(l.size.x / 2, l.size.y + 4)
				l.add_theme_color_override("font_color", Tema.colore_lato(a["lato"]).lightened(0.55))
		l.visible = vis

func _breve(a: Dictionary) -> String:
	var p: String = a["pilota"]
	var parti = p.split(" ")
	return parti[-1] if parti.size() > 0 else p
