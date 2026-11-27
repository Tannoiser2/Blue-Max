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
const ALTEZZA := 250.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# la tabella sta dietro la striscia e sale dal basso
	pannello_tab = PanelContainer.new()
	pannello_tab.add_theme_stylebox_override("panel", Tema.box(Color("efe5cc"), Tema.SEPPIA, 3, 10, 10))
	pannello_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pannello_tab)
	var vt := VBoxContainer.new()
	pannello_tab.add_child(vt)
	vt.add_child(Tema.etichetta("Tabella dei Risultati", 22, Tema.ROSSO, "titolo"))
	tabella = TabellaRisultati.new()
	tabella.custom_minimum_size = Vector2(620, 230)
	vt.add_child(tabella)
	pannello_tab.visible = false
	striscia = PanelContainer.new()
	striscia.add_theme_stylebox_override("panel", Tema.box(Color(0.93, 0.89, 0.79, 0.97), Tema.SEPPIA, 3, 10, 12))
	striscia.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	striscia.offset_left = 400
	striscia.offset_right = -10
	striscia.offset_top = -ALTEZZA - 10
	striscia.offset_bottom = -10
	striscia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(striscia)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	striscia.add_child(v)
	var a := R.aereo(int(ev["da"]))
	var b := R.aereo(int(ev["a"]))
	var chi := "%s spara a %s" % [a["pilota"], b["pilota"]]
	if ev["arma"] == "osservatore":
		chi = "L'osservatore di %s spara a %s" % [a["pilota"], b["pilota"]]
	var testa := HBoxContainer.new()
	v.add_child(testa)
	var t := Tema.titolo(chi, 28, Tema.ROSSO)
	testa.add_child(t)
	var sub := Tema.etichetta("raffica %s - %s contro %s" % [ev["raffica"], Dati.aerei[a["tipo"]]["nome"], Dati.aerei[b["tipo"]]["nome"]], 19, Tema.SEPPIA, "grassetto")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	testa.add_child(sub)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	var sx := VBoxContainer.new()
	sx.custom_minimum_size.x = 560
	sx.add_theme_constant_override("separation", 2)
	h.add_child(sx)
	mods = GridContainer.new()
	mods.columns = 2
	mods.add_theme_constant_override("h_separation", 18)
	mods.add_theme_constant_override("v_separation", 0)
	sx.add_child(mods)
	totale = Tema.etichetta("", 23, Tema.INCHIOSTRO, "grassetto")
	sx.add_child(totale)
	dado = Dado.new()
	dado.custom_minimum_size = Vector2(120, 120)
	dado.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(dado)
	var dx := VBoxContainer.new()
	dx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(dx)
	esito = Tema.etichetta("", 22, Tema.INCHIOSTRO, "grassetto", 300)
	dx.add_child(esito)
	pedine = HBoxContainer.new()
	pedine.add_theme_constant_override("separation", 10)
	pedine.alignment = BoxContainer.ALIGNMENT_END
	pedine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dx.add_child(pedine)

func _t(s: float) -> void:
	await get_tree().create_timer(s * (0.45 if veloce else 1.0)).timeout

func mostra() -> void:
	await get_tree().process_frame
	# la striscia entra dal basso
	var y0 := striscia.position.y
	striscia.position.y = get_viewport_rect().size.y + 10
	var tw := create_tween()
	tw.tween_property(striscia, "position:y", y0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	for m in ev["mod"]:
		var r := HBoxContainer.new()
		var n := Tema.etichetta(m[0], 18, Tema.INCHIOSTRO, "testo")
		n.custom_minimum_size.x = 210
		r.add_child(n)
		var testo := ("%d" % int(m[1])) if m[0].begins_with("Distanza") else ("%+d" % int(m[1]))
		var vv := Tema.etichetta(testo, 18, Tema.ROSSO if int(m[1]) < 0 else Tema.VERDE, "grassetto")
		vv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vv.custom_minimum_size.x = 50
		r.add_child(vv)
		r.modulate.a = 0.0
		mods.add_child(r)
		var t2 := create_tween()
		t2.tween_property(r, "modulate:a", 1.0, 0.18)
		await _t(0.22)
	totale.text = "Valore di fuoco: %d" % int(ev["valore"])
	await _t(0.3)
	var finale: int = int(ev["dado_eff"])
	Suoni.suona("dado")
	await dado.lancia(int(ev["dado"]), 0.9 if not veloce else 0.45)
	if finale != int(ev["dado"]):
		esito.text = "Bonus al Tiro: il dado conta %d" % finale
		await _t(0.5)
	var val := clampi(int(ev["valore"]), 0, 15)
	# la tabella sale dal basso, mostra l'incrocio e si richiude
	if val > 0:
		await get_tree().process_frame
		pannello_tab.visible = true
		var dim := pannello_tab.get_combined_minimum_size()
		var vp := get_viewport_rect().size
		var x := striscia.global_position.x + 560 + 150
		x = minf(x, vp.x - dim.x - 20)
		var alto := striscia.global_position.y - dim.y + 30
		pannello_tab.position = Vector2(x, vp.y)
		var t3 := create_tween()
		t3.tween_property(pannello_tab, "position:y", alto, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await t3.finished
		tabella.segna(finale, val)
		await _t(1.8)
		var t4 := create_tween()
		t4.tween_property(pannello_tab, "position:y", vp.y, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		await t4.finished
		pannello_tab.visible = false
	var b := int(ev["blu"])
	var r2 := int(ev["rosse"])
	if val <= 0:
		esito.text = "Valore di fuoco zero: nessun effetto."
	elif b + r2 == 0:
		esito.text = "Mancato!"
	else:
		var tt := []
		if b > 0:
			tt.append("%d pedin%s blu" % [b, "a" if b == 1 else "e"])
		if r2 > 0:
			tt.append("%d pedin%s ross%s" % [r2, "a" if r2 == 1 else "e", "a" if r2 == 1 else "e"])
		esito.text = "Colpito! " + " e ".join(tt)
		Suoni.suona("colpito")
	await _t(0.4)
	for p in ev["pedine"]:
		var pd := Pedina.new()
		pd.p = p
		pd.coperta = segreto and not (p.get("spec", "") in ["fuoco", "fumo", "esplosione", "oss_ucciso", "pilota_ucciso"])
		pd.custom_minimum_size = Vector2(130, 130)
		pd.modulate.a = 0.0
		pedine.add_child(pd)
		var t5 := create_tween()
		t5.tween_property(pd, "modulate:a", 1.0, 0.15)
		Suoni.suona("pedina")
		await pd.gira()
		await _t(0.3)
	await _t(1.6 if ev["pedine"].size() > 0 else 0.7)
	var t6 := create_tween()
	t6.tween_property(striscia, "position:y", get_viewport_rect().size.y + 10, 0.25)
	await t6.finished


class Dado extends Control:
	var faccia := 1
	var rot := 0.0
	func lancia(v: int, durata: float) -> void:
		var t := 0.0
		var rn := RandomNumberGenerator.new()
		rn.randomize()
		while t < durata:
			faccia = rn.randi_range(1, 6)
			rot = rn.randf_range(-0.6, 0.6)
			queue_redraw()
			await get_tree().create_timer(0.07).timeout
			t += 0.07
		faccia = v
		rot = 0.0
		queue_redraw()
	func _draw() -> void:
		var c := size / 2
		var l := minf(size.x, size.y) * 0.4
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
				if d == riga and v <= col * _t:
					bg = Color("f1dc9b")
				if v == col and d <= riga * _t:
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
			var righe := _a_capo(testo, f, l * 2 - 10, 16)
			var y := -righe.size() * 9.5 + 14
			for rr in righe:
				draw_string(f, Vector2(-l + 4, y), rr, HORIZONTAL_ALIGNMENT_CENTER, l * 2 - 8, 16, Color("1b1b1b"))
				y += 19
		else:
			var f := Tema.font("titolo")
			draw_string(f, Vector2(-l, 8), "Blue Max", HORIZONTAL_ALIGNMENT_CENTER, l * 2, 20, Color("e8dcc0"))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
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
