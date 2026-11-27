class_name SchedaMovimento
extends VBoxContainer
## La Tabella-Movimento Aereo: tutte le manovre dell'aereo disegnate come sulla scheda originale
## (esagono di partenza con la freccia, esagoni attraversati, sagoma dell'aereo all'arrivo).
## Le manovre non consentite sono sbiadite; un tocco seleziona la manovra.

signal scelta(codice: String)

var aereo: Dictionary = {}
var consentite = {}   # codice -> true
var selezionata = ""
var celle = {}

func imposta(a: Dictionary, possibili: Array) -> void:
	aereo = a
	consentite.clear()
	for m in possibili:
		consentite[m["codice"]] = true
	selezionata = ""
	for c in get_children():
		c.queue_free()
	celle.clear()
	var t: Dictionary = Dati.aerei[a["tipo"]]
	var tutte: Array = t["manovre"].duplicate()
	if a["stato"] == "vite" or possibili.size() == 1 and possibili[0].get("forzata", "") != "":
		for m in possibili:
			if not (m["codice"] in tutte):
				tutte.append(m["codice"])
	var gruppi = {}
	for c in tutte:
		if c in a["escluse"]:
			continue
		var k = Dati.codice(c)
		var g = "Acrobatiche (dopo una manovra Avanti)" if k["n"] >= 27 else ("Rotazioni e stallo" if k["n"] <= 1 else "Velocità %d" % k["vel"])
		if c == "0A2":
			g = "Avvitamento"
		if not gruppi.has(g):
			gruppi[g] = []
		gruppi[g].append(c)
	var ordine = ["Avvitamento", "Rotazioni e stallo", "Velocità 1", "Velocità 2", "Velocità 3", "Velocità 4", "Acrobatiche (dopo una manovra Avanti)"]
	for g in ordine:
		if not gruppi.has(g):
			continue
		var lista: Array = gruppi[g]
		lista.sort_custom(func(x, y): return _ordina(x) < _ordina(y))
		var tit = Tema.etichetta(g, 18, Tema.SEPPIA, "grassetto")
		add_child(tit)
		var flusso = HFlowContainer.new()
		flusso.add_theme_constant_override("h_separation", 6)
		flusso.add_theme_constant_override("v_separation", 6)
		add_child(flusso)
		for c in lista:
			var cel = CellaManovra.new()
			cel.codice = c
			cel.attiva = consentite.has(c)
			cel.custom_minimum_size = Vector2(84, 112)
			cel.premuta.connect(_premuta)
			flusso.add_child(cel)
			celle[c] = cel

func _ordina(c: String) -> int:
	var k = Dati.codice(c)
	var d: int = {"S": 0, "A": 1, "D": 2}[k["dir"]]
	return d * 1000 + int(k["n"])

func _premuta(c: String) -> void:
	if not consentite.has(c):
		return
	seleziona(c)
	scelta.emit(c)

func seleziona(c: String) -> void:
	selezionata = c
	for k in celle:
		celle[k].scelta = k == c
		celle[k].queue_redraw()


class CellaManovra extends Control:
	signal premuta(c: String)
	var codice = ""
	var attiva = true
	var scelta = false

	func _gui_input(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			premuta.emit(codice)
			accept_event()

	func _draw() -> void:
		var r = Rect2(Vector2.ZERO, size)
		var fondo = Color("f4ecd8") if attiva else Color("d9cfb9")
		if scelta:
			fondo = Color("f7d77a")
		draw_rect(r, fondo)
		draw_rect(r, Tema.ROSSO if scelta else Tema.SEPPIA, false, 3.0 if scelta else 1.0)
		var g = Dati.geometria(codice)
		var ink = Tema.INCHIOSTRO if attiva else Color("9a8f7c")
		# esagoni piatti in alto (come sulla scheda): N, NE, SE, S, SO, NO
		var lato = 9.0
		var s3 = sqrt(3.0)
		var dirs = {0: Vector2(0, -s3), 1: Vector2(1.5, -s3 / 2), 2: Vector2(1.5, s3 / 2), 3: Vector2(0, s3), -2: Vector2(-1.5, s3 / 2), -1: Vector2(-1.5, -s3 / 2)}
		var p = Vector2.ZERO
		var punti = [p]
		for s in g["passi"]:
			p += dirs[int(s) if int(s) != -3 else 3] * lato
			punti.append(p)
		var stesso: bool = g["passi"].is_empty()
		var mn = Vector2(1e9, 1e9)
		var mx = Vector2(-1e9, -1e9)
		var disegno = punti.duplicate()
		if stesso:
			disegno = [Vector2(-lato * 1.0, 0), Vector2(lato * 1.0, 0)]
		for q in disegno:
			mn = mn.min(q)
			mx = mx.max(q)
		var centro_area = Vector2(size.x / 2, (size.y - 26) / 2 + 2)
		var off: Vector2 = centro_area - (mn + mx) / 2
		for i in disegno.size():
			var c: Vector2 = disegno[i] + off
			var poly = PackedVector2Array()
			for k in 7:
				var ang = deg_to_rad(60 * k)
				poly.append(c + Vector2(cos(ang), sin(ang)) * lato)
			draw_polyline(poly, ink, 1.2, true)
		# partenza: freccia
		var c0: Vector2 = disegno[-1] + off if stesso else disegno[0] + off
		if stesso:
			c0 = disegno[1] + off
		draw_polyline(PackedVector2Array([c0 + Vector2(-3.5, 2), c0 + Vector2(0, -2.5), c0 + Vector2(3.5, 2)]), ink, 1.6, true)
		# arrivo: sagoma dell'aereo
		var cf: Vector2 = (disegno[0] if stesso else disegno[-1]) + off
		var prua = float(g["prua"])
		_aereo(cf, deg_to_rad(prua * 60.0), ink, lato)
		var f = Tema.font("grassetto")
		var tx = codice if not g["non_ripetibile"] else "(" + codice + ")"
		var w = f.get_string_size(tx, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		draw_string(f, Vector2((size.x - w) / 2, size.y - 7), tx, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, ink)

	func _aereo(c: Vector2, ang: float, col: Color, lato: float) -> void:
		var su = Vector2(sin(ang), -cos(ang))
		var dx = Vector2(cos(ang), sin(ang))
		var k = lato * 0.75
		draw_line(c + su * k * 0.55 - dx * k, c + su * k * 0.55 + dx * k, col, 2.6)
		draw_line(c + su * k * 0.9, c - su * k * 0.8, col, 2.2)
		draw_line(c - su * k * 0.8 - dx * k * 0.4, c - su * k * 0.8 + dx * k * 0.4, col, 2.0)
