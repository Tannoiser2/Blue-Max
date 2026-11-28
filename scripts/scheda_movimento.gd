class_name SchedaMovimento
extends Control
## La Tabella-Movimento Aereo disegnata in un solo riquadro che si adatta allo spazio:
## tutte le manovre visibili senza scorrere, riquadri ravvicinati e disegni grandi
## (esagono di partenza con la freccia, esagoni attraversati, sagoma dell'aereo all'arrivo).
## Le manovre non consentite sono sbiadite; un tocco seleziona la manovra.

signal scelta(codice: String)

var aereo: Dictionary = {}
var consentite := {}
var selezionata := ""
var celle := {}        # codice -> Rect2 (calcolati in _layout)
var gruppi := []       # [[etichetta, [codici], Rect2]]
var lampeggio := ""
var _t := 0.0
const GAP := 3.0
const COL_ETICHETTA := 30.0

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(300, 240)
	mouse_filter = Control.MOUSE_FILTER_STOP

func imposta(a: Dictionary, possibili: Array) -> void:
	aereo = a
	consentite.clear()
	for m in possibili:
		consentite[m["codice"]] = true
	selezionata = ""
	var t: Dictionary = Dati.aerei[a["tipo"]]
	var tutte: Array = t["manovre"].duplicate()
	for m in possibili:
		if not (m["codice"] in tutte):
			tutte.append(m["codice"])
	var g := {}
	for c in tutte:
		if c in a["escluse"]:
			continue
		var k := Dati.codice(c)
		var nome := "Acro" if k["n"] >= 27 else ("Rot" if k["n"] <= 1 else "V%d" % k["vel"])
		if c == "0A2":
			nome = "Vite"
		if not g.has(nome):
			g[nome] = []
		g[nome].append(c)
	gruppi.clear()
	for n in ["Vite", "Rot", "V1", "V2", "V3", "V4", "Acro"]:
		if g.has(n):
			var l: Array = g[n]
			l.sort_custom(func(x, y): return _ordina(x) < _ordina(y))
			gruppi.append([n, l, Rect2()])
	_layout()
	queue_redraw()

func _ordina(c: String) -> int:
	var k := Dati.codice(c)
	return {"S": 0, "A": 1, "D": 2}[k["dir"]] * 1000 + int(k["n"])

func _notification(w: int) -> void:
	if w == NOTIFICATION_RESIZED:
		_layout()
		queue_redraw()

## Tre colonne fisse: S a sinistra, A al centro, D a destra; righe per gruppo di velocità.
## Si cerca il riquadro più grande che fa entrare tutto, dividendo le colonne tra S, A e D.
const SEP := 10.0
const TESTA := 22.0
var zone := []   # [x0, x1] per S, A, D

func _per_dir(lista: Array, d: String) -> Array:
	return lista.filter(func(c): return Dati.codice(c)["dir"] == d)

func _layout() -> void:
	celle.clear()
	zone.clear()
	if gruppi.is_empty() or size.x < 50:
		return
	var larg := size.x - COL_ETICHETTA - 2 * SEP
	var alto := size.y - TESTA
	var mass := [0, 0, 0]
	for gr in gruppi:
		for k in 3:
			mass[k] = maxi(mass[k], _per_dir(gr[1], "SAD"[k]).size())
	var migliore := [40.0, [1, 1, 1]]
	for prova in range(140, 29, -2):
		var w := float(prova)
		var h := w * 1.12
		var tot := int((larg + 3 * GAP) / (w + GAP))
		if tot < 3:
			continue
		var buono = null
		var min_righe := 9999
		for cs in range(1, mini(tot - 1, maxi(1, mass[0])) + 1):
			for ca in range(1, mini(tot - cs, maxi(1, mass[1])) + 1):
				var cd := mini(tot - cs - ca, maxi(1, mass[2]))
				if cd < 1:
					continue
				var righe := 0
				for gr in gruppi:
					var n = [_per_dir(gr[1], "S").size(), _per_dir(gr[1], "A").size(), _per_dir(gr[1], "D").size()]
					righe += maxi(1, maxi(int(ceil(n[0] / float(cs))), maxi(int(ceil(n[1] / float(ca))), int(ceil(n[2] / float(cd))))))
				if righe < min_righe:
					min_righe = righe
					buono = [cs, ca, cd]
		if buono != null and min_righe * (h + GAP) + (gruppi.size() - 1) * 4.0 <= alto:
			migliore = [w, buono]
			break
	var w: float = migliore[0]
	var h := w * 1.12
	var col: Array = migliore[1]
	var usato: float = (col[0] + col[1] + col[2]) * (w + GAP) - 3 * GAP
	var x := COL_ETICHETTA + maxf(0.0, (larg - usato) / 2.0)
	for k in 3:
		var x1 = x + col[k] * (w + GAP) - GAP
		zone.append([x, x1])
		x = x1 + GAP + SEP
	var y := TESTA
	for gr in gruppi:
		var righe := 1
		for k in 3:
			var lista := _per_dir(gr[1], "SAD"[k])
			righe = maxi(righe, int(ceil(lista.size() / float(col[k]))))
			# S allineate verso il centro (a destra della loro zona), D verso il centro (a sinistra)
			for i in lista.size():
				var cx: float
				var ic: int = i % int(col[k])
				if k == 0:
					cx = zone[0][1] - w - ic * (w + GAP)
				elif k == 1:
					var nriga := mini(lista.size() - (i / int(col[k])) * int(col[k]), int(col[k]))
					var largo_riga := nriga * (w + GAP) - GAP
					cx = (zone[1][0] + zone[1][1]) / 2 - largo_riga / 2 + ic * (w + GAP)
				else:
					cx = zone[2][0] + ic * (w + GAP)
				celle[lista[i]] = Rect2(cx, y + (i / int(col[k])) * (h + GAP), w, h)
		gr[2] = Rect2(0, y, COL_ETICHETTA - 4, righe * (h + GAP) - GAP)
		y += righe * (h + GAP) + 4.0

func _gui_input(ev: InputEvent) -> void:
	if (ev is InputEventMouseButton or ev is InputEventMouseMotion) and ev.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var p := Vector2(-1, -1)
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		p = ev.position
	elif ev is InputEventScreenTouch and ev.pressed:
		p = ev.position
	if p.x < 0:
		return
	for c in celle:
		if celle[c].has_point(p):
			accept_event()
			if consentite.has(c):
				seleziona(c)
				scelta.emit(c)
			return

func seleziona(c: String) -> void:
	selezionata = c
	queue_redraw()

func lampeggia(c: String) -> void:
	lampeggio = c
	_t = 0.0
	set_process(true)

func _process(dt: float) -> void:
	if lampeggio == "":
		set_process(false)
		return
	_t += dt
	if _t > 5.0:
		lampeggio = ""
	queue_redraw()

func _draw() -> void:
	var f := Tema.font("grassetto")
	var nomi := ["Sinistra (S)", "Avanti (A)", "Destra (D)"]
	var fondi := [Color(0.42, 0.33, 0.22, 0.10), Color(0.42, 0.33, 0.22, 0.0), Color(0.42, 0.33, 0.22, 0.10)]
	for k in zone.size():
		var z: Array = zone[k]
		draw_rect(Rect2(z[0] - 3, 0, z[1] - z[0] + 6, size.y), fondi[k])
		var fs := 15
		var tw := f.get_string_size(nomi[k], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2((z[0] + z[1]) / 2 - tw / 2, 16), nomi[k], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Tema.ROSSO)
		if k > 0:
			var xs = z[0] - SEP / 2 - GAP / 2
			draw_line(Vector2(xs, 0), Vector2(xs, size.y), Color("8c7350"), 2.0)
	for gr in gruppi:
		var r: Rect2 = gr[2]
		if r.size.y <= 0:
			continue
		draw_rect(r, Color("6b5437"))
		var testo: String = gr[0]
		var fs := 15
		draw_set_transform(r.position + Vector2(r.size.x / 2 + 5, r.size.y / 2), -PI / 2, Vector2.ONE)
		var tw := f.get_string_size(testo, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(-tw / 2, 0), testo, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("f3ead6"))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	for c in celle:
		_cella(c, celle[c])

func _cella(codice: String, r: Rect2) -> void:
	var attiva := consentite.has(codice)
	var fondo := Color("f4ecd8") if attiva else Color("d4cab3")
	if codice == selezionata:
		fondo = Color("f7d77a")
	elif codice == lampeggio and attiva:
		fondo = fondo.lerp(Color("f2c14e"), 0.5 + 0.5 * sin(_t * 8.0))
	draw_rect(r, fondo)
	draw_rect(r, Tema.ROSSO if codice == selezionata else Color("8c7350"), false, 3.0 if codice == selezionata else 1.0)
	var g := Dati.geometria(codice)
	var ink := Tema.INCHIOSTRO if attiva else Color("a39882")
	var s3 := sqrt(3.0)
	var dirs := {0: Vector2(0, -s3), 1: Vector2(1.5, -s3 / 2), 2: Vector2(1.5, s3 / 2), 3: Vector2(0, s3), -2: Vector2(-1.5, s3 / 2), -1: Vector2(-1.5, -s3 / 2)}
	var p := Vector2.ZERO
	var punti := [p]
	for s in g["passi"]:
		p += dirs[int(s) if int(s) != -3 else 3]
		punti.append(p)
	var stesso: bool = g["passi"].is_empty()
	var disegno := punti.duplicate()
	if stesso:
		disegno = [Vector2(-1.0, 0), Vector2(1.0, 0)]
	var mn := Vector2(1e9, 1e9)
	var mx := Vector2(-1e9, -1e9)
	for q in disegno:
		mn = mn.min(q)
		mx = mx.max(q)
	var ext := (mx - mn) + Vector2(2.1, 1.9)
	var area := Vector2(r.size.x - 6, r.size.y - 22)
	var lato := minf(minf(area.x / ext.x, area.y / ext.y), r.size.x * 0.2)
	var centro := r.position + Vector2(r.size.x / 2, 3 + area.y / 2)
	var off: Vector2 = centro - (mn + mx) / 2 * lato
	for q in disegno:
		var c: Vector2 = q * lato + off
		var poly := PackedVector2Array()
		for k in 7:
			var ang := deg_to_rad(60 * k)
			poly.append(c + Vector2(cos(ang), sin(ang)) * lato)
		draw_polyline(poly, ink, 1.5, true)
	var c0: Vector2 = (disegno[1] if stesso else disegno[0]) * lato + off
	var fr := lato * 0.4
	draw_polyline(PackedVector2Array([c0 + Vector2(-fr, fr * 0.55), c0 + Vector2(0, -fr * 0.6), c0 + Vector2(fr, fr * 0.55)]), ink, 2.0, true)
	var cf: Vector2 = (disegno[0] if stesso else disegno[-1]) * lato + off
	_aereo(cf, deg_to_rad(float(g["prua"]) * 60.0), ink, lato)
	var f := Tema.font("grassetto")
	var tx := codice if not g["non_ripetibile"] else "(" + codice + ")"
	var fs := clampi(int(r.size.x * 0.2), 12, 19)
	var w := f.get_string_size(tx, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(f, Vector2(r.position.x + (r.size.x - w) / 2, r.end.y - 5), tx, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)

func _aereo(c: Vector2, ang: float, col: Color, lato: float) -> void:
	var su := Vector2(sin(ang), -cos(ang))
	var dx := Vector2(cos(ang), sin(ang))
	var k := lato * 0.72
	var sp := maxf(2.0, lato * 0.16)
	draw_line(c + su * k * 0.45 - dx * k, c + su * k * 0.45 + dx * k, col, sp * 1.2)
	draw_line(c + su * k * 0.95, c - su * k * 0.85, col, sp)
	draw_line(c - su * k * 0.85 - dx * k * 0.42, c - su * k * 0.85 + dx * k * 0.42, col, sp)
