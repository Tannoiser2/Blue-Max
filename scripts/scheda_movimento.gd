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

## Trova la misura del riquadro più grande che fa entrare tutto nello spazio disponibile
func _layout() -> void:
	celle.clear()
	if gruppi.is_empty() or size.x < 50:
		return
	var larg := size.x - COL_ETICHETTA
	var migliore := 40.0
	for prova in range(140, 39, -2):
		var w := float(prova)
		var h := w * 1.12
		var per_riga := maxi(1, int((larg + GAP) / (w + GAP)))
		var righe := 0
		for gr in gruppi:
			righe += int(ceil(float(gr[1].size()) / per_riga))
		if righe * (h + GAP) + (gruppi.size() - 1) * 4.0 <= size.y:
			migliore = w
			break
	var w := migliore
	var h := w * 1.12
	var per_riga := maxi(1, int((larg + GAP) / (w + GAP)))
	var y := 0.0
	for gr in gruppi:
		var lista: Array = gr[1]
		var righe := int(ceil(float(lista.size()) / per_riga))
		for i in lista.size():
			celle[lista[i]] = Rect2(COL_ETICHETTA + (i % per_riga) * (w + GAP), y + (i / per_riga) * (h + GAP), w, h)
		gr[2] = Rect2(0, y, COL_ETICHETTA - 4, righe * (h + GAP) - GAP)
		y += righe * (h + GAP) + 4.0

func _gui_input(ev: InputEvent) -> void:
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
