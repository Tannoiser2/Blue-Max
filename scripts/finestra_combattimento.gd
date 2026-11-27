class_name FinestraCombattimento
extends Control
## Risoluzione animata di un attacco in una striscia in basso, senza coprire il centro dell'azione:
## in alto chi spara a chi; sotto, a sinistra, i modificatori che compaiono uno alla volta,
## poi il dado; dal basso sale la Tabella dei Risultati con l'incrocio, resta un momento e si richiude;
## a destra le pedine-danno estratte una dopo l'altra.

var R: Regole
var ev: Dictionary
var segreto := false
var veloce := false
var striscia: PanelContainer
var mods: GridContainer
var dado: Dado
var tabella: TabellaRisultati
var pannello_tab: PanelContainer
var pedine: HBoxContainer
var esito: Label
var totale: Label
const ALTEZZA := 182.0
const LATO := 135.0   # valore di fuoco, dado e pedine: tutti quadrati uguali
var box_valore: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# la tabella sale dal basso sopra la striscia mentre si tira il dado
	pannello_tab = PanelContainer.new()
	pannello_tab.add_theme_stylebox_override("panel", Tema.box(Color("efe5cc"), Tema.SEPPIA, 3, 10, 10))
	pannello_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pannello_tab)
	var vt := VBoxContainer.new()
	pannello_tab.add_child(vt)
	vt.add_child(Tema.etichetta("Tabella dei Risultati", 22, Tema.ROSSO, "titolo"))
	tabella = TabellaRisultati.new()
	tabella.custom_minimum_size = Vector2(620, 220)
	vt.add_child(tabella)
	pannello_tab.visible = false
	striscia = PanelContainer.new()
	striscia.add_theme_stylebox_override("panel", Tema.box(Color(0.93, 0.89, 0.79, 0.97), Tema.SEPPIA, 3, 10, 8))
	striscia.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	striscia.offset_left = 10
	striscia.offset_right = -10
	striscia.offset_top = -ALTEZZA - 10
	striscia.offset_bottom = -10
	striscia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(striscia)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	striscia.add_child(v)
	var a := R.aereo(int(ev["da"]))
	var b := R.aereo(int(ev["a"]))
	var chi := "%s spara a %s" % [a["pilota"], b["pilota"]]
	if ev["arma"] == "osservatore":
		chi = "L'osservatore di %s spara a %s" % [a["pilota"], b["pilota"]]
	var testa := HBoxContainer.new()
	v.add_child(testa)
	testa.add_child(Tema.titolo(chi, 24, Tema.ROSSO))
	esito = Tema.etichetta("", 22, Tema.INCHIOSTRO, "grassetto")
	esito.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	esito.custom_minimum_size.x = 260
	testa.add_child(esito)
	var sub := Tema.etichetta("raffica %s - %s contro %s" % [ev["raffica"], Dati.aerei[a["tipo"]]["nome"], Dati.aerei[b["tipo"]]["nome"]], 17, Tema.SEPPIA, "grassetto")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	testa.add_child(sub)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	# 1. modificatori
	mods = GridContainer.new()
	mods.columns = 2
	mods.custom_minimum_size.x = 540
	mods.add_theme_constant_override("h_separation", 16)
	mods.add_theme_constant_override("v_separation", 0)
	h.add_child(mods)
	# 2. valore di fuoco
	var pv := PanelContainer.new()
	pv.add_theme_stylebox_override("panel", Tema.box(Color("f8f1df"), Tema.ROSSO, 3, 4, 2))
	pv.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pv.custom_minimum_size = Vector2(LATO, LATO)
	h.add_child(pv)
	var vv := VBoxContainer.new()
	vv.add_theme_constant_override("separation", 0)
	pv.add_child(vv)
	var lv := Tema.etichetta("Valore di fuoco", 17, Tema.SEPPIA, "grassetto")
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vv.add_child(lv)
	box_valore = Tema.etichetta("", 80, Tema.ROSSO, "titolo")
	box_valore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vv.add_child(box_valore)
	# 3. dado
	dado = Dado.new()
	dado.custom_minimum_size = Vector2(LATO, LATO)
	dado.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	dado.visible = false
	h.add_child(dado)
	# 4. esito e pedine
	var dx := HBoxContainer.new()
	dx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dx.add_theme_constant_override("separation", 10)
	h.add_child(dx)

	pedine = HBoxContainer.new()
	pedine.add_theme_constant_override("separation", 6)
	dx.add_child(pedine)
	totale = esito

func _t(s: float) -> void:
	await get_tree().create_timer(s * (0.45 if veloce else 1.0)).timeout

func mostra() -> void:
	await get_tree().process_frame
	var y0 := striscia.position.y
	striscia.position.y = get_viewport_rect().size.y + 10
	var tw := create_tween()
	tw.tween_property(striscia, "position:y", y0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	for m in ev["mod"]:
		var r := HBoxContainer.new()
		var n := Tema.etichetta(m[0], 19, Tema.INCHIOSTRO, "testo")
		n.custom_minimum_size.x = 215
		r.add_child(n)
		var testo := ("%d" % int(m[1])) if m[0].begins_with("Distanza") else ("%+d" % int(m[1]))
		var vl := Tema.etichetta(testo, 19, Tema.ROSSO if int(m[1]) < 0 else Tema.VERDE, "grassetto")
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vl.custom_minimum_size.x = 36
		r.add_child(vl)
		r.modulate.a = 0.0
		mods.add_child(r)
		create_tween().tween_property(r, "modulate:a", 1.0, 0.15)
		await _t(0.18)
	box_valore.text = str(int(ev["valore"]))
	box_valore.pivot_offset = box_valore.size / 2
	box_valore.scale = Vector2(1.6, 1.6)
	create_tween().tween_property(box_valore, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	await _t(0.4)
	var finale: int = int(ev["dado_eff"])
	var val := clampi(int(ev["valore"]), 0, 15)
	# la tabella sale, con la colonna del valore di fuoco già segnata
	var vp := get_viewport_rect().size
	if val > 0:
		pannello_tab.visible = true
		await get_tree().process_frame
		var dim := pannello_tab.get_combined_minimum_size()
		var x := minf(striscia.global_position.x + 650, vp.x - dim.x - 20)
		var alto := striscia.global_position.y - dim.y - 6
		pannello_tab.position = Vector2(x, vp.y)
		tabella.col = val - 1
		tabella.queue_redraw()
		var t3 := create_tween()
		t3.tween_property(pannello_tab, "position:y", alto, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await t3.finished
	# il dado rotola e la riga evidenziata lo segue
	dado.visible = true
	Suoni.suona("dado")
	dado.al_cambio = func(f): tabella.riga = f - 1; tabella.queue_redraw()
	await dado.lancia(int(ev["dado"]), 1.0 if not veloce else 0.5)
	dado.al_cambio = Callable()
	if finale != int(ev["dado"]):
		esito.text = "Bonus al Tiro: conta %d" % finale
		await _t(0.4)
	if val > 0:
		tabella.segna(finale, val)
		await _t(1.3)
		var t4 := create_tween()
		t4.tween_property(pannello_tab, "position:y", vp.y, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		await t4.finished
		pannello_tab.visible = false
	var b := int(ev["blu"])
	var r2 := int(ev["rosse"])
	if val <= 0:
		esito.text = "Valore zero: nessun effetto"
	elif b + r2 == 0:
		esito.text = "Mancato!"
	else:
		esito.text = "Colpito!"
		Suoni.suona("colpito")
	for p in ev["pedine"]:
		var pd := Pedina.new()
		pd.p = p
		pd.coperta = segreto and not (p.get("spec", "") in ["fuoco", "fumo", "esplosione", "oss_ucciso", "pilota_ucciso"])
		var n_ped: int = ev["pedine"].size()
		var spazio: float = pedine.get_parent().size.x
		var lato_p: float = clampf(spazio / n_ped - 8.0, 90.0, LATO)
		pd.custom_minimum_size = Vector2(lato_p, lato_p)
		pd.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		pedine.add_child(pd)
		Suoni.suona("pedina")
		await pd.gira()
		await _t(0.25)
	await _t(1.8 if ev["pedine"].size() > 0 else 0.9)
	var t6 := create_tween()
	t6.tween_property(striscia, "position:y", vp.y + 10, 0.25)
	await t6.finished


class Dado extends Control:
	var faccia := 1
	var rot := 0.0
	var al_cambio := Callable()
	func lancia(v: int, durata: float) -> void:
		var t := 0.0
		var rn := RandomNumberGenerator.new()
		rn.randomize()
		while t < durata:
			faccia = rn.randi_range(1, 6)
			rot = rn.randf_range(-0.6, 0.6)
			if al_cambio.is_valid():
				al_cambio.call(faccia)
			queue_redraw()
			await get_tree().create_timer(0.07).timeout
			t += 0.07
		faccia = v
		rot = 0.0
		if al_cambio.is_valid():
			al_cambio.call(faccia)
		queue_redraw()
	func _draw() -> void:
		var c := size / 2
		var l := (minf(size.x, size.y) * 0.5 - 2) * (1.0 - 0.3 * absf(sin(rot * 2.0)))
		draw_set_transform(c, rot, Vector2.ONE)
		var r := Rect2(-Vector2(l, l), Vector2(l, l) * 2)
		draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.25))
		draw_rect(r, Color("f8f3e6"))
		draw_rect(r, Tema.INCHIOSTRO, false, 3.0)
		var p := {1: [Vector2(0, 0)], 2: [Vector2(-1, -1), Vector2(1, 1)], 3: [Vector2(-1, -1), Vector2(0, 0), Vector2(1, 1)],
			4: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)],
			5: [Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0), Vector2(-1, 1), Vector2(1, 1)],
			6: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, 1)]}
		for q in p[faccia]:
			draw_circle(q * l * 0.5, l * 0.15, Tema.ROSSO if faccia == 1 else Tema.INCHIOSTRO)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


class TabellaRisultati extends Control:
	var riga := -1
	var col := -1
	var _t := 0.0
	func segna(d: int, v: int) -> void:
		riga = d - 1
		col = v - 1
		var tw := create_tween()
		tw.tween_method(func(x): _t = x; queue_redraw(), 0.0, 1.0, 0.6)
	func _draw() -> void:
		var f := Tema.font("grassetto")
		var cw := (size.x - 26) / 15.0
		var ch := (size.y - 22) / 6.0
		draw_rect(Rect2(Vector2.ZERO, size), Color("f4ecd8"))
		for v in 15:
			draw_string(f, Vector2(26 + v * cw, 16), str(v + 1), HORIZONTAL_ALIGNMENT_CENTER, cw, 15, Tema.SEPPIA)
		for d in 6:
			draw_string(f, Vector2(4, 22 + d * ch + ch * 0.68), str(d + 1), HORIZONTAL_ALIGNMENT_LEFT, 20, 16, Tema.SEPPIA)
			for v in 15:
				var re := Rect2(26 + v * cw, 22 + d * ch, cw, ch)
				var x: Array = Dati.comb["risultati"][d][v]
				var bg := Color("f4ecd8")
				# l'evidenziazione scorre lungo riga e colonna
				if v == col or d == riga:
					bg = Color("f1dc9b")
				if d == riga and v == col and _t >= 1.0:
					bg = Tema.ROSSO_CHIARO
				draw_rect(re, bg)
				draw_rect(re, Color("c9b994"), false, 1.0)
				var t := ""
				if int(x[0]) > 0:
					t += ("%dB" % int(x[0])) if int(x[0]) > 1 else "B"
				if int(x[1]) > 0:
					t += ("%dR" % int(x[1])) if int(x[1]) > 1 else "R"
				if t == "":
					t = "-"
				draw_string(f, re.position + Vector2(0, ch * 0.7), t, HORIZONTAL_ALIGNMENT_CENTER, cw, 14, Color.WHITE if (d == riga and v == col and _t >= 1.0) else Tema.INCHIOSTRO)


class Pedina extends Control:
	var p: Dictionary
	var coperta := false
	var scoperta := false
	var sx := 1.0
	func gira() -> void:
		var tw := create_tween()
		tw.tween_method(func(t: float):
			sx = absf(cos(t * PI))
			if t > 0.5:
				scoperta = true
			queue_redraw(), 0.0, 1.0, 0.45)
		await tw.finished
	func _draw() -> void:
		var c := size / 2
		draw_set_transform(c, 0, Vector2(maxf(sx, 0.03), 1))
		var l := minf(size.x, size.y) * 0.5 - 2
		var r := Rect2(-Vector2(l, l), Vector2(l, l) * 2)
		var rossa: bool = p.get("colore", "B") == "R"
		var col := Color("e0574d") if rossa else Color("4aa6dc")
		if not scoperta:
			col = Color("6b5437")
		draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.3))
		draw_rect(r, col)
		draw_rect(r, Color(1, 1, 1, 0.5), false, 2.0)
		if scoperta:
			var testo := "colpo a segno" if coperta else Dati.testo_pedina(p)
			var f := Tema.font("grassetto")
			var fs := 18 if righe_n(testo, f, l) <= 4 else 15
			var righe := _a_capo(testo, f, l * 2 - 10, fs)
			var y := -righe.size() * (fs + 3) / 2.0 + fs * 0.8
			for rr in righe:
				draw_string(f, Vector2(-l + 4, y), rr, HORIZONTAL_ALIGNMENT_CENTER, l * 2 - 8, fs, Color("1b1b1b"))
				y += fs + 3
		else:
			var f := Tema.font("titolo")
			draw_string(f, Vector2(-l, 8), "Blue Max", HORIZONTAL_ALIGNMENT_CENTER, l * 2, 20, Color("e8dcc0"))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	func righe_n(t: String, f: Font, l: float) -> int:
		return _a_capo(t, f, l * 2 - 10, 18).size()
	func _a_capo(t: String, f: Font, w: float, s: int) -> Array:
		var out := []
		for par in t.split("\n"):
			var riga := ""
			for parola in par.split(" "):
				var prova := parola if riga == "" else riga + " " + parola
				if f.get_string_size(prova, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x > w and riga != "":
					out.append(riga)
					riga = parola
				else:
					riga = prova
			if riga != "":
				out.append(riga)
		return out
