class_name VistaDanni
extends SubViewportContainer
## La miniatura dell'aereo che mostra i danni subiti: fori di proiettile su ali, fusoliera e coda
## in proporzione alle caselle perse, tela lacerata che sventola, bruciature, motore che fuma o perde olio,
## fumo e fiamme, mitragliatrici inceppate o distrutte, osservatore colpito.
## Si fa ruotare trascinando (mouse o dito); da sola gira piano.

var vp: SubViewport
var radice: Node3D
var modello: Node3D
var danni: Node3D
var cam: Camera3D
var yaw := 0.6
var pitch := 0.45
var trascina := false
var auto := true
var aereo: Dictionary = {}
var tipo := ""
var etichette: Label
static var _vertici := {}   # tipo -> {"ali": [[pos, normale]], "fus": ..., "coda": ..., "muso": ...}

const MODELLI := {"snipe": "camel", "pfalz_d12": "pfalz_d3", "ssw_d4": "ssw_d3"}

func _init() -> void:
	stretch = true
	custom_minimum_size = Vector2(360, 330)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_2X
	add_child(vp)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("2b241b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("cfc4ad")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.85
	we.environment = env
	vp.add_child(we)
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-50, 30, 0)
	l.light_energy = 0.8
	vp.add_child(l)
	var l2 := DirectionalLight3D.new()
	l2.rotation_degrees = Vector3(-20, 210, 0)
	l2.light_energy = 0.3
	vp.add_child(l2)
	radice = Node3D.new()
	vp.add_child(radice)
	cam = Camera3D.new()
	cam.fov = 38
	vp.add_child(cam)
	etichette = Label.new()
	etichette.add_theme_font_override("font", Tema.font("grassetto"))
	etichette.add_theme_font_size_override("font_size", 15)
	etichette.add_theme_color_override("font_color", Color("f3ead6"))
	etichette.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	etichette.add_theme_constant_override("outline_size", 5)
	etichette.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	etichette.grow_vertical = Control.GROW_DIRECTION_BEGIN
	etichette.position = Vector2(8, 0)
	etichette.offset_left = 8
	etichette.offset_bottom = -6
	etichette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(etichette)

func _process(dt: float) -> void:
	if not is_visible_in_tree():
		return
	if auto and not trascina:
		yaw += dt * 0.35
	var d := 1.3
	cam.position = Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * d
	cam.look_at(Vector3.ZERO, Vector3.UP)

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		trascina = ev.pressed
		if ev.pressed:
			auto = false
		accept_event()
	elif ev is InputEventScreenTouch:
		trascina = ev.pressed
		auto = false
		accept_event()
	elif (ev is InputEventMouseMotion and trascina) or ev is InputEventScreenDrag:
		yaw -= ev.relative.x * 0.01
		pitch = clampf(pitch + ev.relative.y * 0.01, -1.2, 1.4)
		accept_event()

## Mostra l'aereo con i suoi danni. segreto: del nemico si vedono solo fumo, fuoco e osservatore ucciso.
func imposta(a: Dictionary, segreto: bool) -> void:
	aereo = a
	if tipo != a["tipo"]:
		tipo = a["tipo"]
		if modello:
			modello.queue_free()
		var sc = load("res://assets/modelli/%s.glb" % MODELLI.get(tipo, tipo))
		modello = sc.instantiate() if sc else Node3D.new()
		radice.add_child(modello)
		_prepara_vertici(tipo, modello)
	if danni:
		danni.queue_free()
	danni = Node3D.new()
	radice.add_child(danni)
	var t: Dictionary = Dati.aerei[tipo]
	var testo := []
	if not segreto:
		var fa := 1.0 - float(a["ali"]) / float(t["ali"])
		var ff := 1.0 - float(a["fus"]) / float(t["fusoliera"])
		var fc := 1.0 - float(a["coda"]) / float(t["coda"])
		var fm := 1.0 - float(a["motore"]) / float(t["motore"])
		_fori("ali", int(round(fa * 26)), 11)
		_fori("fus", int(round(ff * 18)), 23)
		_fori("coda", int(round(fc * 10)), 37)
		_fori("muso", int(round(fm * 6)), 41)
		if fa >= 0.45 or a["no_acro"]:
			_lacerazioni(int(clampf(fa * 8, 2, 7)))
		if ff >= 0.6:
			_bruciature("fus", int(ff * 6), 53)
		if fm > 0.0:
			_scia(Vector3(0, 0.02, 0.42), Color(0.08, 0.07, 0.06, 0.55) if fm < 1.0 else Color(0.05, 0.05, 0.05, 0.85), 0.5 + fm)
		if fa > 0:
			testo.append("Ali: %d%% di danni" % int(fa * 100))
		if ff > 0:
			testo.append("Fusoliera: %d%%%s" % [int(ff * 100), " - DISTRUTTA" if a["fus"] <= 0 else (" - bucata" if ff < 0.6 else " - devastata")])
		if fc > 0:
			testo.append("Coda: %d%%" % int(fc * 100))
		if fm > 0:
			testo.append("Motore: %s" % ("fermo" if a["motore"] <= 0 else "perde olio"))
		var i := 0
		for m in a["mitra"]:
			var x := -0.04 + 0.08 * i if a["mitra"].size() > 1 else 0.0
			if m["distrutta"]:
				_segno(Vector3(x, 0.1, 0.25), Color("d0302a"))
				testo.append("Mitragliatrice distrutta")
			elif m["inceppata"]:
				_segno(Vector3(x, 0.1, 0.25), Color("e8b93a"))
				testo.append("Mitragliatrice INCEPPATA")
			i += 1
		if not a["timone"].is_empty():
			_segno(Vector3(0, 0.08, -0.4), Color("e8b93a"))
			testo.append("Timone inceppato")
		if a["no_veloce"]:
			testo.append("Niente velocità 3-4")
	else:
		testo.append("Danni del nemico non visibili")
	if not a["oss"].is_empty():
		if not a["oss"]["vivo"]:
			_segno(Vector3(0, 0.12, -0.05), Color("d0302a"))
			testo.append("Osservatore ucciso")
		elif int(a["oss"]["ferito"]) > 0 and not segreto:
			testo.append("Osservatore ferito")
	if a["fumo"]:
		_scia(Vector3(0, 0.03, 0.35), Color(0.4, 0.39, 0.37, 0.7), 1.5)
		testo.append("Perde fumo")
	if a["fuoco"]:
		var f := Effetti.fiamme()
		f.local_coords = true
		danni.add_child(f)
		f.position = Vector3(0, 0.05, 0.25)
		_scia(Vector3(0, 0.08, 0.2), Color(0.1, 0.09, 0.08, 0.85), 2.0)
		testo.append("IN FIAMME")
	if a["stato"] == "abbattuto":
		testo.append("ABBATTUTO")
	if testo.is_empty():
		testo.append("Nessun danno")
	etichette.text = "\n".join(testo)

static func _prepara_vertici(t: String, mod: Node3D) -> void:
	if _vertici.has(t):
		return
	var reg := {"ali": [], "fus": [], "coda": [], "muso": []}
	for mi in mod.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = mi.mesh
		if m == null:
			continue
		var tr: Transform3D = (mi as MeshInstance3D).transform
		var p: Node = mi.get_parent()
		while p != null and p != mod:
			if p is Node3D:
				tr = (p as Node3D).transform * tr
			p = p.get_parent()
		for s in m.get_surface_count():
			var arr := m.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
			var passo := maxi(1, v.size() / 1500)
			for i in range(0, v.size(), passo):
				var pos: Vector3 = tr * v[i]
				var nor: Vector3 = (tr.basis * n[i]).normalized() if i < n.size() else Vector3.UP
				var k := ""
				if absf(pos.x) > 0.16:
					k = "ali"
				elif pos.z < -0.22:
					k = "coda"
				elif pos.z > 0.3:
					k = "muso"
				elif absf(pos.x) < 0.09:
					k = "fus"
				if k != "":
					reg[k].append([pos, nor])
	_vertici[t] = reg

func _fori(regione: String, n: int, seme: int) -> void:
	var lista: Array = _vertici.get(tipo, {}).get(regione, [])
	if lista.is_empty() or n <= 0:
		return
	var rn := RandomNumberGenerator.new()
	rn.seed = hash(tipo) + int(aereo["id"]) * 977 + seme
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.04, 0.03)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var bordo := StandardMaterial3D.new()
	bordo.albedo_color = Color(0.42, 0.32, 0.2, 0.85)
	bordo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bordo.cull_mode = BaseMaterial3D.CULL_DISABLED
	bordo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in n:
		var x: Array = lista[rn.randi_range(0, lista.size() - 1)]
		var pos: Vector3 = x[0]
		var nor: Vector3 = x[1]
		var r := rn.randf_range(0.018, 0.032)
		for k in 2:
			var d := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = r * (1.0 if k == 0 else 1.6)
			cm.bottom_radius = cm.top_radius
			cm.height = 0.002
			cm.radial_segments = 7
			d.mesh = cm
			d.material_override = mat if k == 0 else bordo
			danni.add_child(d)
			var su := Vector3.FORWARD if absf(nor.dot(Vector3.UP)) > 0.95 else Vector3.UP
			d.basis = Basis.looking_at(nor, su) * Basis(Vector3.RIGHT, PI / 2)
			d.position = pos + nor * (0.004 - 0.001 * k)

func _lacerazioni(n: int) -> void:
	var lista: Array = _vertici.get(tipo, {}).get("ali", [])
	if lista.is_empty():
		return
	var rn := RandomNumberGenerator.new()
	rn.seed = hash(tipo) + int(aereo["id"]) * 131
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("d9ceb0")
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in n:
		# brandelli di tela vicino al bordo delle ali
		var best: Array = lista[0]
		for k in 12:
			var c: Array = lista[rn.randi_range(0, lista.size() - 1)]
			if absf(c[0].x) > absf(best[0].x) * rn.randf_range(0.8, 1.0):
				best = c
		var q := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.05, 0.08, 0.003)
		q.mesh = pm
		q.material_override = mat
		danni.add_child(q)
		q.position = best[0] + Vector3(0, -0.01, -0.03)
		q.rotation = Vector3(rn.randf_range(-0.5, 0.5), rn.randf_range(0, TAU), PI)
		var tw := q.create_tween().set_loops()
		var r0 := q.rotation
		tw.tween_property(q, "rotation:x", r0.x + 0.7, rn.randf_range(0.15, 0.3))
		tw.tween_property(q, "rotation:x", r0.x - 0.3, rn.randf_range(0.15, 0.3))

func _bruciature(regione: String, n: int, seme: int) -> void:
	var lista: Array = _vertici.get(tipo, {}).get(regione, [])
	if lista.is_empty():
		return
	var rn := RandomNumberGenerator.new()
	rn.seed = hash(tipo) + int(aereo["id"]) * 31 + seme
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.06, 0.04, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in n:
		var x: Array = lista[rn.randi_range(0, lista.size() - 1)]
		var d := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = rn.randf_range(0.04, 0.07)
		cm.bottom_radius = cm.top_radius
		cm.height = 0.002
		cm.radial_segments = 9
		d.mesh = cm
		d.material_override = mat
		danni.add_child(d)
		var nor: Vector3 = x[1]
		var su := Vector3.FORWARD if absf(nor.dot(Vector3.UP)) > 0.95 else Vector3.UP
		d.basis = Basis.looking_at(nor, su) * Basis(Vector3.RIGHT, PI / 2)
		d.position = x[0] + nor * 0.005

func _scia(pos: Vector3, col: Color, forza: float) -> void:
	var p := Effetti.scia_fumo(col)
	p.local_coords = true
	p.direction = Vector3(0, 0.6, -1)
	p.initial_velocity_min = 0.15
	p.initial_velocity_max = 0.35
	p.amount = int(18 * forza)
	p.lifetime = 1.2
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.5
	danni.add_child(p)
	p.position = pos

func _segno(pos: Vector3, col: Color) -> void:
	var s := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.025
	sm.height = 0.05
	s.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 0.6
	s.material_override = m
	danni.add_child(s)
	s.position = pos
	var tw := s.create_tween().set_loops()
	tw.tween_property(s, "scale", Vector3.ONE * 1.5, 0.5)
	tw.tween_property(s, "scale", Vector3.ONE, 0.5)
