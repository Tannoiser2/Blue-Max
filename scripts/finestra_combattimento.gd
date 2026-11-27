class_name FinestraCombattimento
extends PanelContainer
## Risoluzione animata di un attacco: modificatori, lancio del dado, incrocio sulla Tabella dei Risultati,
## estrazione delle pedine-danno che si girano una alla volta.

var R: Regole
var ev: Dictionary
var segreto = false
var veloce = false
var dado: Dado
var tabella: TabellaRisultati
var pedine: HBoxContainer
var esito: Label
signal chiuso

func _ready() -> void:
	add_theme_stylebox_override("panel", Tema.box(Tema.CARTA, Tema.SEPPIA, 3, 10, 18))
	custom_minimum_size = Vector2(880, 0)
	var v = VBoxContainer.new()
	add_child(v)
	var a = R.aereo(int(ev["da"]))
	var b = R.aereo(int(ev["a"]))
	var chi = "%s spara a %s" % [a["pilota"], b["pilota"]]
	if ev["arma"] == "osservatore":
		chi = "L'osservatore di %s spara a %s" % [a["pilota"], b["pilota"]]
	v.add_child(Tema.titolo(chi, 32, Tema.ROSSO))
	v.add_child(Tema.etichetta("Raffica %s - %s contro %s" % [ev["raffica"], Dati.aerei[a["tipo"]]["nome"], Dati.aerei[b["tipo"]]["nome"]], 20, Tema.SEPPIA, "grassetto"))
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	v.add_child(h)
	var mods = VBoxContainer.new()
	mods.custom_minimum_size.x = 360
	h.add_child(mods)
	for m in ev["mod"]:
		var r = HBoxContainer.new()
		var n = Tema.etichetta(m[0], 19, Tema.INCHIOSTRO, "testo")
		n.custom_minimum_size.x = 260
		r.add_child(n)
		var vv = Tema.etichetta(("%d" % int(m[1])) if m[0].begins_with("Distanza") else ("%+d" % int(m[1])), 19, Tema.ROSSO if int(m[1]) < 0 else Tema.VERDE, "grassetto")
		vv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vv.custom_minimum_size.x = 60
		r.add_child(vv)
		mods.add_child(r)
	var tot = Tema.etichetta("Valore di fuoco: %d" % int(ev["valore"]), 24, Tema.INCHIOSTRO, "grassetto")
	mods.add_child(tot)
	var dx = VBoxContainer.new()
	h.add_child(dx)
	dado = Dado.new()
	dado.custom_minimum_size = Vector2(110, 110)
	dado.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dx.add_child(dado)
	tabella = TabellaRisultati.new()
	tabella.custom_minimum_size = Vector2(440, 170)
	dx.add_child(tabella)
	esito = Tema.etichetta("", 22, Tema.INCHIOSTRO, "grassetto", 820)
	v.add_child(esito)
	pedine = HBoxContainer.new()
	pedine.add_theme_constant_override("separation", 10)
	pedine.alignment = BoxContainer.ALIGNMENT_CENTER
	pedine.custom_minimum_size.y = 4
	v.add_child(pedine)

func _t(s: float) -> void:
	await get_tree().create_timer(s * (0.4 if veloce else 1.0)).timeout

func mostra() -> void:
	await get_tree().process_frame
	await _t(0.6)
	var finale: int = int(ev["dado_eff"])
	var rete = get_tree().root.get_node_or_null("Main/Rete")
	if rete:
		rete.suono("dado")
	await dado.lancia(int(ev["dado"]), 0.9 if not veloce else 0.4)
	if finale != int(ev["dado"]):
		esito.text = "Bonus al Tiro: il dado conta %d" % finale
		await _t(0.6)
	var val = clampi(int(ev["valore"]), 0, 15)
	tabella.segna(finale, val)
	var b = int(ev["blu"])
	var r = int(ev["rosse"])
	if val <= 0:
		esito.text = "Il valore di fuoco è zero: nessun effetto."
	elif b + r == 0:
		esito.text = "Mancato!"
	else:
		var t = []
		if b > 0:
			t.append("%d pedin%s blu" % [b, "a" if b == 1 else "e"])
		if r > 0:
			t.append("%d pedin%s ross%s" % [r, "a" if r == 1 else "e", "a" if r == 1 else "e"])
		esito.text = "Colpito! Si estraggono " + " e ".join(t) + "."
	await _t(0.8)
	for p in ev["pedine"]:
		var pd = Pedina.new()
		pd.p = p
		pd.coperta = segreto and not (p.get("spec", "") in ["fuoco", "fumo", "esplosione", "oss_ucciso", "pilota_ucciso"])
		pd.custom_minimum_size = Vector2(124, 124)
		pedine.add_child(pd)
		await pd.gira()
		await _t(0.25)
	await _t(1.4 if ev["pedine"].size() > 0 else 0.6)


class Dado extends Control:
	var faccia = 1
	var rot = 0.0
	func lancia(v: int, durata: float) -> void:
		var t = 0.0
		var rn = RandomNumberGenerator.new()
		while t < durata:
			faccia = rn.randi_range(1, 6)
			rot = rn.randf_range(-0.5, 0.5)
			queue_redraw()
			await get_tree().create_timer(0.07).timeout
			t += 0.07
		faccia = v
		rot = 0.0
		queue_redraw()
	func _draw() -> void:
		var c = size / 2
		var l = minf(size.x, size.y) * 0.42
		draw_set_transform(c, rot, Vector2.ONE)
		var r = Rect2(-Vector2(l, l), Vector2(l, l) * 2)
		draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.25))
		draw_rect(r, Color("f8f3e6"))
		draw_rect(r, Tema.INCHIOSTRO, false, 3.0)
		var p = {1: [Vector2(0, 0)], 2: [Vector2(-1, -1), Vector2(1, 1)], 3: [Vector2(-1, -1), Vector2(0, 0), Vector2(1, 1)],
			4: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)],
			5: [Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0), Vector2(-1, 1), Vector2(1, 1)],
			6: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, 1)]}
		for q in p[faccia]:
			draw_circle(q * l * 0.5, l * 0.15, Tema.ROSSO if faccia == 1 else Tema.INCHIOSTRO)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


class TabellaRisultati extends Control:
	var riga = -1
	var col = -1
	func segna(d: int, v: int) -> void:
		riga = d - 1
		col = v - 1
		queue_redraw()
	func _draw() -> void:
		var f = Tema.font("grassetto")
		var cw = (size.x - 22) / 15.0
		var ch = (size.y - 20) / 6.0
		draw_rect(Rect2(Vector2.ZERO, size), Color("f4ecd8"))
		for v in 15:
			draw_string(f, Vector2(22 + v * cw + 2, 14), str(v + 1), HORIZONTAL_ALIGNMENT_CENTER, cw - 4, 12, Tema.SEPPIA)
		for d in 6:
			draw_string(f, Vector2(2, 20 + d * ch + ch * 0.7), str(d + 1), HORIZONTAL_ALIGNMENT_LEFT, 18, 13, Tema.SEPPIA)
			for v in 15:
				var re = Rect2(22 + v * cw, 20 + d * ch, cw, ch)
				var x: Array = Dati.comb["risultati"][d][v]
				var bg = Color("f4ecd8")
				if d == riga or v == col:
					bg = Color("f1dc9b")
				if d == riga and v == col:
					bg = Tema.ROSSO_CHIARO
				draw_rect(re, bg)
				draw_rect(re, Color("c9b994"), false, 1.0)
				var t = ""
				if int(x[0]) > 0:
					t += ("%dB" % int(x[0])) if int(x[0]) > 1 else "B"
				if int(x[1]) > 0:
					t += ("%dR" % int(x[1])) if int(x[1]) > 1 else "R"
				if t == "":
					t = "-"
				draw_string(f, re.position + Vector2(0, ch * 0.72), t, HORIZONTAL_ALIGNMENT_CENTER, cw, 11, Color.WHITE if (d == riga and v == col) else Tema.INCHIOSTRO)


class Pedina extends Control:
	var p: Dictionary
	var coperta = false
	var scoperta = false
	var sx = 1.0
	func gira() -> void:
		var tw = create_tween()
		tw.tween_method(func(t: float):
			sx = absf(cos(t * PI))
			if t > 0.5:
				scoperta = true
			queue_redraw(), 0.0, 1.0, 0.45)
		await tw.finished
	func _draw() -> void:
		var c = size / 2
		draw_set_transform(c, 0, Vector2(maxf(sx, 0.03), 1))
		var l = minf(size.x, size.y) * 0.5 - 2
		var r = Rect2(-Vector2(l, l), Vector2(l, l) * 2)
		var rossa: bool = p.get("colore", "B") == "R"
		var col = Color("e0574d") if rossa else Color("4aa6dc")
		if not scoperta:
			col = Color("6b5437")
		draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.3))
		draw_rect(r, col)
		draw_rect(r, Color(1, 1, 1, 0.5), false, 2.0)
		if scoperta:
			var testo = "colpo a segno" if coperta else Dati.testo_pedina(p)
			var f = Tema.font("grassetto")
			var righe = _a_capo(testo, f, l * 2 - 10, 14)
			var y = -righe.size() * 8.5 + 12
			for rr in righe:
				draw_string(f, Vector2(-l + 4, y), rr, HORIZONTAL_ALIGNMENT_CENTER, l * 2 - 8, 14, Color("1b1b1b"))
				y += 17
		else:
			var f = Tema.font("titolo")
			draw_string(f, Vector2(-l, 8), "Blue Max", HORIZONTAL_ALIGNMENT_CENTER, l * 2, 18, Color("e8dcc0"))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	func _a_capo(t: String, f: Font, w: float, s: int) -> Array:
		var out = []
		for par in t.split("\n"):
			var riga = ""
			for parola in par.split(" "):
				var prova = parola if riga == "" else riga + " " + parola
				if f.get_string_size(prova, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x > w and riga != "":
					out.append(riga)
					riga = parola
				else:
					riga = prova
			if riga != "":
				out.append(riga)
		return out
