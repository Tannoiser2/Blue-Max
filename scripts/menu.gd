class_name Menu
extends Control
## Menu principale, scelta degli scenari, schermaglia libera, telefoni, crediti.

var principale
var sfondo: TextureRect
var contenuto: Control
var opz_ia = "veterano"
var veloce = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sfondo = TextureRect.new()
	sfondo.texture = load("res://assets/img/menu.webp")
	sfondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sfondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sfondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sfondo)
	var ombra = ColorRect.new()
	ombra.color = Color(0.06, 0.05, 0.03, 0.35)
	ombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ombra)
	contenuto = Control.new()
	contenuto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(contenuto)
	principale_menu()

func _pulisci() -> void:
	for c in contenuto.get_children():
		c.queue_free()

func _colonna(larg := 560) -> VBoxContainer:
	var p = Tema.pannello(Color(0.91, 0.86, 0.75, 0.96), Tema.SEPPIA, 22)
	p.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	p.position = Vector2(70, 0)
	p.custom_minimum_size = Vector2(larg, 0)
	var cc = MarginContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.add_theme_constant_override("margin_left", 60)
	cc.add_theme_constant_override("margin_top", 40)
	cc.add_theme_constant_override("margin_bottom", 40)
	contenuto.add_child(cc)
	var hb = HBoxContainer.new()
	cc.add_child(hb)
	var vc = VBoxContainer.new()
	vc.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(vc)
	vc.add_child(p)
	var sc = ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(larg, 0)
	p.add_child(sc)
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	sc.add_child(v)
	# altezza: tutto lo schermo meno i margini
	sc.custom_minimum_size.y = minf(940, get_viewport_rect().size.y - 120)
	return v

## Pagina a tutto schermo, senza scorrimento
func _pagina_piena() -> VBoxContainer:
	var cc = MarginContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["left", "right", "top", "bottom"]:
		cc.add_theme_constant_override("margin_" + k, 24)
	contenuto.add_child(cc)
	var p = Tema.pannello(Color(0.93, 0.89, 0.79, 0.96), Tema.SEPPIA, 16)
	cc.add_child(p)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	return v

func principale_menu() -> void:
	_pulisci()
	var cc = MarginContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["left", "right", "top", "bottom"]:
		cc.add_theme_constant_override("margin_" + k, 50)
	contenuto.add_child(cc)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 50)
	cc.add_child(h)
	var p = Tema.pannello(Color(0.93, 0.89, 0.79, 0.96), Tema.SEPPIA, 26)
	p.custom_minimum_size.x = 600
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(p)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var t = Tema.titolo("Blue Max", 110, Tema.ROSSO)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var st = Tema.etichetta("Duelli aerei nel cielo di Francia  -  1916-1918", 24, Tema.SEPPIA, "documento")
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(st)
	v.add_child(_fregio())
	var sal = ""
	if principale.rete:
		sal = principale.rete.carica("bluemax_partita")
	if sal != "":
		v.add_child(_voce("Riprendi la partita", "il duello interrotto, dal turno salvato", _riprendi.bind(sal), true))
	v.add_child(_voce("Tutorial", "impara a volare con l'istruttore, turno per turno", _tutorial))
	v.add_child(_voce("Scenari storici", "%d duelli veri, con gli Assi della Grande Guerra" % (Scenari.ELENCO.size() + Scenari.STORICI.size()), scenari))
	v.add_child(_voce("Generatore di scenari", "scegli epoca, aerei per parte e regole: lo scenario è servito", generatore))
	v.add_child(_voce("Schermaglia libera", "componi tu le squadriglie, aereo per aereo", schermaglia))
	v.add_child(_voce("Campagna", "da novellino a Asso, missione dopo missione", _campagna))
	v.add_child(_voce("Online e telefoni", "crea una partita per gli amici o entra nella loro", online))
	var hb = HBoxContainer.new()
	v.add_child(hb)
	for b in [["Regolamento", func(): add_child(Regolamento.new())], ["Crediti", crediti]]:
		var bt = Tema.bottone(b[0], b[1], 20)
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(bt)
	var nota = Tema.etichetta("Gioco originale GDW (1983), edizione italiana Stratelibri (1993). Conversione digitale per uso personale.", 15, Tema.SEPPIA, "testo", 540)
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nota)
	# a destra la copertina come una cartolina
	var dx = CenterContainer.new()
	dx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(dx)
	var cart = Tema.pannello(Color("f3ead6"), Color("f3ead6"), 12)
	var tex = TextureRect.new()
	tex.texture = load("res://assets/img/copertina.webp")
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	var alt = minf(780.0, get_viewport_rect().size.y - 160)
	tex.custom_minimum_size = Vector2(alt * 0.753, alt)
	cart.add_child(tex)
	cart.rotation_degrees = 3.0
	dx.add_child(cart)
	await get_tree().process_frame
	cart.pivot_offset = cart.size / 2

func _fregio() -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(0, 18)
	c.draw.connect(func():
		var w = c.size.x
		var y = c.size.y / 2
		c.draw_line(Vector2(30, y), Vector2(w / 2 - 22, y), Tema.SEPPIA, 2.0)
		c.draw_line(Vector2(w / 2 + 22, y), Vector2(w - 30, y), Tema.SEPPIA, 2.0)
		c.draw_circle(Vector2(w / 2, y), 7, Tema.ROSSO)
		c.draw_circle(Vector2(w / 2, y), 4, Color("e8dcc0"))
		c.draw_circle(Vector2(w / 2, y), 2, Tema.BLU))
	return c

## Voce del menu: titolo grande e una riga di spiegazione
func _voce(titolo: String, sotto: String, cb: Callable, oro := false) -> Button:
	var b = Button.new()
	b.custom_minimum_size = Vector2(540, 66)
	b.focus_mode = Control.FOCUS_NONE
	var col = Tema.ORO if oro else Tema.ROSSO
	b.add_theme_stylebox_override("normal", Tema.box(col, Color("4a1210"), 2, 8, 10))
	b.add_theme_stylebox_override("hover", Tema.box(col.lightened(0.15), Tema.ORO, 3, 8, 10))
	b.add_theme_stylebox_override("pressed", Tema.box(col.darkened(0.2), Color("4a1210"), 2, 8, 10))
	b.pressed.connect(cb)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", -4)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 18
	v.offset_top = 6
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var colt = Tema.INCHIOSTRO if oro else Color("f6eedb")
	var l1 = Tema.etichetta(titolo, 28, colt, "titolo")
	l1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l1)
	var l2 = Tema.etichetta(sotto, 16, colt.darkened(0.1) if oro else Color("e8d6c0"), "testo")
	l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l2)
	return b

## Carta con immagine (scenari, situazioni, regole opzionali)
func _carta(img: String, titolo: String, sopra: String, testo: String, larg: float, cb: Callable, scelta := false, alta := 0.0, parola := "ATTIVA") -> Button:
	var b = Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(larg, alta if alta > 0 else larg * 1.25)
	var bordo = Tema.ORO if scelta else Tema.SEPPIA
	b.add_theme_stylebox_override("normal", Tema.box(Color("f3ead6") if not scelta else Color("f7e3a8"), bordo, 4 if scelta else 2, 8, 6))
	b.add_theme_stylebox_override("hover", Tema.box(Color("fbf3df"), Tema.ROSSO, 3, 8, 6))
	b.add_theme_stylebox_override("pressed", Tema.box(Color("f7e3a8"), Tema.ORO, 3, 8, 6))
	b.pressed.connect(cb)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_right = -8
	v.offset_top = 8
	v.offset_bottom = -6
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var tex = TextureRect.new()
	var t = load(img) if ResourceLoader.exists(img) else load("res://assets/img/copertina.webp")
	tex.texture = t
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex.custom_minimum_size = Vector2(larg - 16, minf((larg - 16) * 0.62, alta * 0.5) if alta > 0 else (larg - 16) * 0.62)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not scelta and alta > 0:
		tex.modulate = Color(0.8, 0.8, 0.8)
	v.add_child(tex)
	if sopra != "":
		var ls = Tema.etichetta(sopra, 15, Tema.ROSSO, "grassetto")
		ls.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(ls)
	var lt = Tema.etichetta(titolo, 21, Tema.INCHIOSTRO, "titolo", int(larg - 16))
	lt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(lt)
	if testo != "":
		var lx = Tema.etichetta(testo, 15, Tema.SEPPIA, "testo", int(larg - 16))
		lx.max_lines_visible = 4 if alta <= 0 else maxi(1, int((alta * 0.5 - 95) / 19))
		lx.clip_text = false
		lx.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lx.tooltip_text = testo
		lx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(lx)
	if scelta:
		var spunta = Tema.etichetta(parola, 15, Tema.VERDE, "grassetto")
		spunta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(spunta)
	return b

func _riprendi(s: String) -> void:
	var d = JSON.parse_string(s)
	if not (d is Dictionary) or not d.has("S"):
		return
	var R = Regole.new(d["S"])
	var opz = {"livelli": d.get("livelli", {"G": "veterano", "A": "veterano"}), "campagna": d.get("campagna", {})}
	principale.avvia_partita(R, opz)
	principale.gioco.storia = d.get("storia", [])

func _tutorial() -> void:
	var t = Tutorial.new()
	var R = t.prepara()
	principale.avvia_partita(R, {"tutorial": t, "livelli": {"G": "recluta", "A": "veterano"}})

func _campagna() -> void:
	var c = Campagna.new()
	c.menu = self
	_pulisci()
	contenuto.add_child(c)

func ritorno_campagna(camp: Dictionary, R: Regole, turni: int) -> void:
	var c = Campagna.new()
	c.menu = self
	_pulisci()
	contenuto.add_child(c)
	c.fine_missione(camp, R, turni)

# --------------------------------------------------------------------------- scenari
var scenario_scelto = ""
var giochi_con = 0

const SCELTE_CHI = ["Io con gli Alleati", "Io con i Tedeschi", "Due giocatori sullo stesso schermo",
	"Io con gli Alleati, amici online o telefono con i Tedeschi", "Io con i Tedeschi, amici online o telefono con gli Alleati",
	"Tutti online o con il telefono (questo schermo fa da tabellone)", "Guardo il computer"]

func _scelta_chi(attuale: int, cb: Callable) -> OptionButton:
	var ob = OptionButton.new()
	for t in SCELTE_CHI:
		ob.add_item(t)
	ob.selected = attuale
	ob.item_selected.connect(cb)
	ob.custom_minimum_size.x = 560
	ob.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return ob

## Assegna i piloti secondo la scelta «Giochi con»: tu, computer o online/telefono
func _controlli(chi: int) -> Dictionary:
	match chi:
		0: return {"A": "umano", "G": "ia"}
		1: return {"A": "ia", "G": "umano"}
		2: return {"A": "umano", "G": "umano"}
		3: return {"A": "umano", "G": "telefono"}
		4: return {"A": "telefono", "G": "umano"}
		5: return {"A": "telefono", "G": "telefono"}
	return {"A": "ia", "G": "ia"}

func _parti(R: Regole, chi: int) -> void:
	for a in R.S["aerei"]:
		a["controllo"] = _controlli(chi)[a["lato"]]
		if chi == 2:
			a["giocatore"] = "Alleati" if a["lato"] == "A" else "Tedeschi"
	if R.S["aerei"].any(func(x): return x["controllo"] == "telefono"):
		telefoni(R)
		return
	principale.avvia_partita(R, {"livelli": {"G": opz_ia, "A": opz_ia}, "veloce": veloce})

func scenari() -> void:
	_pulisci()
	var v = _pagina_piena()
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var t = Tema.titolo("Scenari storici", 44, Tema.ROSSO)
	t.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	h.add_child(t)
	h.add_child(_etichetta_fissa("Giochi con:"))
	h.add_child(_scelta_chi(giochi_con, func(k): giochi_con = k))
	h.add_child(_etichetta_fissa("Computer:"))
	h.add_child(_scelta_ia())
	var ind = Tema.bottone("Indietro", principale_menu, 20)
	h.add_child(ind)
	var tutti = []
	for x in Scenari.ELENCO:
		tutti.append(x)
	for x in Scenari.STORICI:
		tutti.append(x)
	var vp = get_viewport_rect().size
	var col = 5
	var righe = int(ceil(tutti.size() / float(col)))
	var larg = (vp.x - 48 - 32 - (col - 1) * 10) / col
	var alta = (vp.y - 48 - 32 - 70 - (righe - 1) * 10) / righe
	var g = GridContainer.new()
	g.columns = col
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	v.add_child(g)
	for x in tutti:
		var id: String = x["id"]
		var img = "res://assets/img/scenari/s%d.webp" % int(x.get("img", 1))
		g.add_child(_carta(img, x["titolo"], x.get("data", ""), x["testo"], larg, func(): _gioca_scenario(id), false, alta))

func _etichetta_fissa(t: String) -> Label:
	var l = Tema.etichetta(t, 22, Tema.INCHIOSTRO, "grassetto")
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return l

func _gioca_scenario(id: String) -> void:
	var R = Scenari.costruisci(id, {"G": "ia", "A": "ia"}, {"seme": randi(), "togli_pilota_ucciso": true})
	_parti(R, giochi_con)

func _scelta_ia() -> OptionButton:
	var oi = OptionButton.new()
	for t in ["Recluta", "Veterano", "Asso"]:
		oi.add_item(t)
	oi.selected = ["recluta", "veterano", "asso"].find(opz_ia)
	oi.item_selected.connect(func(i): opz_ia = ["recluta", "veterano", "asso"][i])
	oi.custom_minimum_size.x = 180
	return oi

# --------------------------------------------------------------------------- schermaglia libera
var squadre = {"G": [], "A": []}
var opzioni_partita = {"togli_pilota_ucciso": true, "danni_visibili": false, "carburante_meta": false, "tabella_corretta": false, "collisioni": false, "coda_piu_uno": false, "tiro_vite": false, "osservatore_limitato": false}

func schermaglia() -> void:
	if squadre["G"].is_empty() and squadre["A"].is_empty():
		squadre["G"] = [{"tipo": "fokker_dr1", "nazione": "germania", "controllo": "ia", "esperienza": "veterano", "quota": 2}]
		squadre["A"] = [{"tipo": "camel", "nazione": "inghilterra", "controllo": "umano", "esperienza": "veterano", "quota": 2}]
	_pulisci()
	var v = _colonna(1280)
	v.add_child(Tema.titolo("Schermaglia libera", 52, Tema.ROSSO))
	v.add_child(Tema.etichetta("Scegli fino a sei aerei per parte. Per ogni aereo decidi chi lo pilota: tu (anche in più persone a turno sullo stesso schermo), il computer o un telefono (inquadrando il QR code).", 19, Tema.SEPPIA, "testo", 1200))
	v.add_child(Tema.etichetta("Esperienza del pilota: il NOVELLINO non può tallonare i nemici né fare acrobazie e va in vite più facilmente (4-6 invece di 5-6); il VETERANO vola senza limitazioni; l'ASSO ha 5 abbattimenti e abilità speciali (bonus al tiro, mira, acrobazie). Puoi anche scegliere un Asso storico, con le sue abilità.", 17, Tema.INCHIOSTRO, "testo", 1200))
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	v.add_child(h)
	for lato in ["G", "A"]:
		var col = VBoxContainer.new()
		col.custom_minimum_size.x = 600
		h.add_child(col)
		col.add_child(Tema.etichetta("Tedeschi" if lato == "G" else "Alleati", 30, Tema.colore_lato(lato), "titolo"))
		for i in squadre[lato].size():
			col.add_child(_riga_aereo(lato, i))
		if squadre[lato].size() < 6:
			col.add_child(Tema.bottone("Aggiungi un aereo", func():
				var tipo = "albatros_d5" if lato == "G" else "spad13"
				squadre[lato].append({"tipo": tipo, "nazione": "germania" if lato == "G" else "francia", "controllo": "ia", "esperienza": "veterano", "quota": 2})
				schermaglia(), 20))
	var ho = HFlowContainer.new()
	v.add_child(ho)
	ho.add_child(Tema.etichetta("Computer:", 21, Tema.INCHIOSTRO, "grassetto"))
	ho.add_child(_scelta_ia())
	v.add_child(_carte_opzioni(schermaglia))
	var hb = HBoxContainer.new()
	v.add_child(hb)
	hb.add_child(Tema.bottone("Indietro", principale_menu, 22))
	hb.add_child(Tema.bottone("Decolla!", _avvia_schermaglia, 28, 260))

func _riga_aereo(lato: String, i: int) -> Control:
	var x: Dictionary = squadre[lato][i]
	var p = Tema.pannello(Color("f3ead6"), Tema.SEPPIA, 8)
	var g = GridContainer.new()
	g.columns = 3
	p.add_child(g)
	# nazione
	var on = OptionButton.new()
	var naz = ["germania"] if lato == "G" else ["inghilterra", "francia", "usa"]
	for n in naz:
		on.add_item(Dati.NAZIONI[n]["nome"])
	on.selected = maxi(0, naz.find(x["nazione"]))
	on.custom_minimum_size.x = 180
	on.item_selected.connect(func(k):
		x["nazione"] = naz[k]
		var ok = _aerei_di(x["nazione"])
		if not (x["tipo"] in ok):
			x["tipo"] = ok[0]
		schermaglia())
	if lato == "A":
		g.add_child(on)
	else:
		var lt = Tema.etichetta("Luftstreitkräfte", 20, Tema.TEDESCHI, "titolo")
		lt.custom_minimum_size.x = 180
		g.add_child(lt)
	var oa = OptionButton.new()
	var tipi = _aerei_di(x["nazione"])
	for t in tipi:
		var nome: String = Dati.aerei[t]["nome"]
		oa.add_item("%s  (%s)" % [nome, Scenari.nome_mese(int(Dati.aerei[t]["disponibile_dal"])).split(" ")[1]])
	oa.selected = maxi(0, tipi.find(x["tipo"]))
	oa.custom_minimum_size.x = 280
	oa.item_selected.connect(func(k): x["tipo"] = tipi[k])
	g.add_child(oa)
	var oc = OptionButton.new()
	for t in ["Tu", "Computer", "Online o telefono"]:
		oc.add_item(t)
	oc.selected = ["umano", "ia", "telefono"].find(x["controllo"])
	oc.custom_minimum_size.x = 140
	oc.item_selected.connect(func(k): x["controllo"] = ["umano", "ia", "telefono"][k])
	g.add_child(oc)
	var oe = OptionButton.new()
	var esp = ["novellino", "veterano", "asso"]
	var assi = Scenari.ASSI.keys().filter(func(k): return Dati.NAZIONI[Scenari.ASSI[k]["nazione"]]["lato"] == lato)
	for t in ["Novellino", "Veterano", "Asso (abilità a scelta del computer)"]:
		oe.add_item(t)
	for k in assi:
		oe.add_item(Scenari.ASSI[k]["nome"])
	var tutte = esp + assi
	oe.selected = maxi(0, tutte.find(x["esperienza"]))
	oe.custom_minimum_size.x = 180
	oe.item_selected.connect(func(k): x["esperienza"] = tutte[k])
	g.add_child(oe)
	var oq = OptionButton.new()
	for q in Dati.QUOTE:
		oq.add_item("Quota " + q)
	oq.selected = int(x["quota"])
	oq.item_selected.connect(func(k): x["quota"] = k)
	g.add_child(oq)
	g.add_child(Tema.bottone("Togli", func(): squadre[lato].remove_at(i); schermaglia(), 18))
	var t: Dictionary = Dati.aerei[x["tipo"]]
	if t["provvisorio"] != "":
		var n = Tema.etichetta("Nota: " + t["provvisorio"], 15, Tema.ROSSO, "testo", 560)
		var vv = VBoxContainer.new()
		p.remove_child(g)
		vv.add_child(g)
		vv.add_child(n)
		p.add_child(vv)
	return p

func _aerei_di(naz: String) -> Array:
	return Dati.ordine_aerei.filter(func(t): return naz in Dati.aerei[t]["nazioni"])

func _pilota(x: Dictionary, n: int) -> Dictionary:
	var e: String = x["esperienza"]
	if Scenari.ASSI.has(e):
		return Scenari.pilota_asso(e)
	var nomi_g = ["Leutnant Wolff", "Vizefeldwebel Hahn", "Leutnant Bauer", "Oberleutnant Kraus", "Leutnant Schulz", "Unteroffizier Lang"]
	var nomi_a = {"inghilterra": ["Capt. Mannock", "Lt. Barker", "Lt. Ball", "Capt. McCudden", "Lt. Rhys Davids", "Lt. Collins"],
		"francia": ["Lt. Nungesser", "Sgt. Fonck", "Adj. Dorme", "Lt. Navarre", "Sgt. Garros", "Cpl. Bastien"],
		"usa": ["Lt. Rickenbacker", "Lt. Luke", "Lt. Campbell", "Lt. Winslow", "Lt. Meissner", "Lt. Coolidge"]}
	var nome: String = nomi_g[n % 6] if x["nazione"] == "germania" else nomi_a[x["nazione"]][n % 6]
	var p = {"nome": nome, "novellino": e == "novellino", "abbattimenti": 0, "abilita": []}
	if e == "asso":
		p["abbattimenti"] = 6
		p["abilita"] = ["bonus_tiro", "mira", "acrobatiche"]
	return p

func _avvia_schermaglia() -> void:
	var lista = []
	var n = 0
	for lato in ["G", "A"]:
		for x in squadre[lato]:
			lista.append({"tipo": x["tipo"], "nazione": x["nazione"], "controllo": x["controllo"], "quota": x["quota"], "pilota": _pilota(x, n)})
			n += 1
	var g = lista.filter(func(x): return Dati.NAZIONI[x["nazione"]]["lato"] == "G")
	var a = lista.filter(func(x): return Dati.NAZIONI[x["nazione"]]["lato"] == "A")
	if g.is_empty() or a.is_empty():
		return
	var opz = opzioni_partita.duplicate()
	opz["seme"] = randi()
	var R = Scenari.schermaglia(lista, opz, true)
	# più persone sullo stesso schermo: la manovra si sceglie a turno e in segreto
	var umani = R.S["aerei"].filter(func(x): return x["controllo"] == "umano")
	var lati = {}
	for u in umani:
		lati[u["lato"]] = true
	if lati.size() > 1:
		for u in umani:
			u["giocatore"] = u["pilota"]
	if R.S["aerei"].any(func(x): return x["controllo"] == "telefono"):
		telefoni(R)
		return
	principale.avvia_partita(R, {"livelli": {"G": opz_ia, "A": opz_ia}, "veloce": veloce})

const OPZIONI = [
	["togli_pilota_ucciso", "Senza «Pilota ucciso»", "Si toglie la pedina che abbatte subito l'aereo: duelli meno casuali (consigliato).", 1],
	["danni_visibili", "Danni visibili", "Si vedono i danni dei nemici: niente segretezza.", 2],
	["carburante_meta", "Carburante dimezzato", "Ogni manovra consuma metà carburante: duelli più lunghi.", 3],
	["tabella_corretta", "Tabella corretta GDW", "Stabilità C solo +1 a bruciapelo; -4/-1 contro chi è a quota diversa.", 4],
	["collisioni", "Collisioni in volo", "Stesso esagono e stessa quota: chi fa lo stesso numero col dado si scontra.", 5],
	["coda_piu_uno", "Coda più robusta", "Una casella di coda in più a tutti gli aerei.", 6],
	["tiro_vite", "Bersaglio in vite", "-2 contro chi è in avvitamento, sempre tiro angolato.", 7],
	["osservatore_limitato", "Osservatore realistico", "L'osservatore spara solo se il pilota vola dritto o va in stallo.", 8],
]

## Le regole opzionali come carte illustrate: un tocco le attiva o le spegne
func _carte_opzioni(ridisegna: Callable, larg := 0.0, alta := 0.0) -> Control:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.add_child(Tema.etichetta("Regole opzionali", 22, Tema.INCHIOSTRO, "titolo"))
	var compatto = larg > 0
	var lc = 220.0
	var ac = 300.0
	if compatto:
		lc = (larg - 3 * 8) / 4
		ac = (alta - 130) / 2
	var g = GridContainer.new()
	g.columns = 4 if compatto else 8
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	v.add_child(g)
	for o in OPZIONI:
		var k: String = o[0]
		g.add_child(_carta("res://assets/img/opzioni/o%d.webp" % int(o[3]), o[1], "", o[2], lc, func():
			opzioni_partita[k] = not opzioni_partita.get(k, false)
			ridisegna.call(), opzioni_partita.get(k, false), ac))
	var hn = HBoxContainer.new()
	v.add_child(hn)
	var ln = Tema.etichetta("Nuvole (regola della casa)", 20, Tema.INCHIOSTRO, "grassetto")
	ln.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	ln.custom_minimum_size.x = 270
	ln.tooltip_text = "Chi è dentro una nuvola (stesso esagono e stessa quota) prende -2 al tiro contro di lui, spara con -1 e non può essere tallonato."
	ln.mouse_filter = Control.MOUSE_FILTER_PASS
	hn.add_child(ln)
	for q in [[0, "Nessuna"], [4, "Poche"], [9, "Molte"], [16, "Tante"]]:
		var b = Tema.bottone(q[1], func(): opzioni_partita["nuvole"] = q[0]; ridisegna.call(), 19, 110)
		if int(opzioni_partita.get("nuvole", 0)) == q[0]:
			b.add_theme_stylebox_override("normal", Tema.box(Tema.ORO, Tema.INCHIOSTRO, 2, 6, 8))
			b.add_theme_color_override("font_color", Tema.INCHIOSTRO)
		hn.add_child(b)
	var cv = CheckBox.new()
	cv.text = "Animazioni veloci"
	cv.button_pressed = veloce
	cv.toggled.connect(func(x): veloce = x)
	hn.add_child(cv)
	if not compatto:
		v.add_child(Tema.etichetta("Nuvole: chi è dentro una nuvola (stesso esagono e stessa quota) prende -2 al tiro contro di lui, spara con -1 e non può essere tallonato.", 16, Tema.SEPPIA, "testo", 1200))
	return v

# --------------------------------------------------------------------------- generatore di scenari
var gen = {"mese": 7, "n_g": 2, "n_a": 2, "situazione": "incontro", "chi": 0, "anteprima": {}}

func generatore() -> void:
	_pulisci()
	var v = _pagina_piena()
	var vp = get_viewport_rect().size
	var testa = HBoxContainer.new()
	v.add_child(testa)
	var t = Tema.titolo("Generatore di scenari", 44, Tema.ROSSO)
	testa.add_child(t)
	testa.add_child(Tema.bottone("Indietro", principale_menu, 20))
	var corpo = HBoxContainer.new()
	corpo.add_theme_constant_override("separation", 18)
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(corpo)
	# colonna sinistra: impostazioni e anteprima
	var sx = VBoxContainer.new()
	sx.custom_minimum_size.x = 640
	corpo.add_child(sx)
	var g = GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 12)
	sx.add_child(g)
	g.add_child(_etichetta_fissa("Epoca"))
	var he = HBoxContainer.new()
	g.add_child(he)
	var lm = Tema.etichetta(Scenari.nome_mese(gen["mese"]), 22, Tema.ROSSO, "titolo")
	lm.custom_minimum_size.x = 200
	var sl = HSlider.new()
	sl.min_value = -12
	sl.max_value = 22
	sl.value = gen["mese"]
	sl.custom_minimum_size = Vector2(300, 34)
	sl.drag_ended.connect(func(_c): gen["anteprima"] = {}; generatore())
	sl.value_changed.connect(func(x): gen["mese"] = int(x); lm.text = Scenari.nome_mese(int(x)))
	he.add_child(sl)
	he.add_child(lm)
	for lato in [["n_g", "Tedeschi"], ["n_a", "Alleati"]]:
		g.add_child(_etichetta_fissa(lato[1]))
		var hn = HBoxContainer.new()
		g.add_child(hn)
		for n in range(1, 7):
			var b = Tema.bottone(str(n), func(): gen[lato[0]] = n; gen["anteprima"] = {}; generatore(), 20, 52)
			if gen[lato[0]] == n:
				b.add_theme_stylebox_override("normal", Tema.box(Tema.ORO, Tema.INCHIOSTRO, 2, 6, 8))
				b.add_theme_color_override("font_color", Tema.INCHIOSTRO)
			hn.add_child(b)
	g.add_child(_etichetta_fissa("Giochi con"))
	g.add_child(_scelta_chi(gen["chi"], func(k): gen["chi"] = k))
	g.add_child(_etichetta_fissa("Computer"))
	var oi = _scelta_ia()
	oi.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	g.add_child(oi)
	if gen["anteprima"].is_empty():
		var rn = RandomNumberGenerator.new()
		rn.randomize()
		gen["anteprima"] = Scenari.genera(gen["mese"], gen["n_g"], gen["n_a"], gen["situazione"], rn)
	var an: Dictionary = gen["anteprima"]
	var p = Tema.pannello(Color("f7efdb"), Tema.ROSSO, 10)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sx.add_child(p)
	var vpn = VBoxContainer.new()
	vpn.add_theme_constant_override("separation", 2)
	p.add_child(vpn)
	vpn.add_child(Tema.titolo("%s - %s" % [Scenari.SITUAZIONI[gen["situazione"]]["nome"], Scenari.nome_mese(gen["mese"])], 24, Tema.ROSSO))
	for lato in ["G", "A"]:
		vpn.add_child(Tema.etichetta("Tedeschi" if lato == "G" else "Alleati", 18, Tema.colore_lato(lato), "grassetto"))
		for x in an["aerei"]:
			if Dati.NAZIONI[x["nazione"]]["lato"] != lato:
				continue
			var pil: Dictionary = x["pilota"]
			var esp = "Asso" if int(pil.get("abbattimenti", 0)) >= 5 else ("novellino" if pil.get("novellino", false) else "veterano")
			vpn.add_child(Tema.etichetta("%s - %s, %s, quota %s" % [Dati.aerei[x["tipo"]]["nome"], pil["nome"], esp, Dati.QUOTE[int(x["quota"])]], 16, Tema.INCHIOSTRO, "testo"))
	var hb = HBoxContainer.new()
	sx.add_child(hb)
	hb.add_child(Tema.bottone("Rigenera", func(): gen["anteprima"] = {}; generatore(), 22))
	var dec = Tema.bottone("Decolla!", _avvia_generato, 28, 260)
	hb.add_child(dec)
	# colonna destra: situazioni e regole opzionali
	var dx = VBoxContainer.new()
	dx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	corpo.add_child(dx)
	var largd = vp.x - 48 - 32 - 640 - 18
	var altd = vp.y - 48 - 32 - 60
	dx.add_child(Tema.etichetta("Situazione", 22, Tema.INCHIOSTRO, "titolo"))
	var gs = HBoxContainer.new()
	gs.add_theme_constant_override("separation", 8)
	dx.add_child(gs)
	var ls = (largd - 4 * 8) / 5
	for k in Scenari.SITUAZIONI:
		var x: Dictionary = Scenari.SITUAZIONI[k]
		gs.add_child(_carta("res://assets/img/scenari/s%d.webp" % int(x["img"]), x["nome"], "", "", ls, func(): gen["situazione"] = k; gen["anteprima"] = {}; generatore(), gen["situazione"] == k, altd * 0.3, "SCELTA"))
	dx.add_child(_carte_opzioni(generatore, largd, altd * 0.62))

func _avvia_generato() -> void:
	var an: Dictionary = gen["anteprima"]
	var lista = []
	for x in an["aerei"]:
		var y: Dictionary = x.duplicate(true)
		var lato: String = Dati.NAZIONI[y["nazione"]]["lato"]
		var umano = (gen["chi"] == 0 and lato == "A") or (gen["chi"] == 1 and lato == "G") or gen["chi"] == 2
		y["controllo"] = "umano" if umano else "ia"
		if gen["chi"] == 2:
			y["pilota"]["giocatore"] = "Alleati" if lato == "A" else "Tedeschi"
		lista.append(y)
	var opz = opzioni_partita.duplicate()
	opz["seme"] = randi()
	var R = Scenari.schermaglia(lista, opz, an["vicino"])
	R.S["scenario"] = "generato"
	_parti(R, gen["chi"])

# --------------------------------------------------------------------------- telefoni
func telefoni(R: Regole) -> void:
	_pulisci()
	var v = _colonna(1100)
	v.add_child(Tema.titolo("Partita online e telefoni", 52, Tema.ROSSO))
	v.add_child(Tema.etichetta("Ogni pilota «Online o telefono» può entrare in due modi, anche da un'altra città: dal telefono, inquadrando il QR code (sceglie manovre e raffiche in segreto, con la mappa piccola), oppure con il gioco completo da un altro computer o iPad, aprendo Blue Max e scegliendo «Entra in una partita online» con il codice della stanza. Chi entra prende il primo aereo libero; potete cambiare l'assegnazione qui sotto.", 20, Tema.SEPPIA, "testo", 1040))
	var rete: Rete = principale.rete
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	v.add_child(h)
	var qr = QR.new()
	qr.custom_minimum_size = Vector2(300, 300)
	h.add_child(qr)
	var dx = VBoxContainer.new()
	dx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(dx)
	var lbl_url = Tema.etichetta("Apro la stanza...", 22, Tema.INCHIOSTRO, "grassetto", 680)
	dx.add_child(lbl_url)
	var elenco = VBoxContainer.new()
	dx.add_child(elenco)
	var giocatori = {}   # uid -> nome
	var assegna = {}     # id aereo -> uid
	var ridisegna = func():
		for c in elenco.get_children():
			c.queue_free()
		for a in R.S["aerei"]:
			if a["controllo"] != "telefono":
				continue
			var hh = HBoxContainer.new()
			hh.add_child(Tema.etichetta("%s (%s)" % [a["pilota"], Dati.aerei[a["tipo"]]["nome"]], 20, Tema.colore_lato(a["lato"]), "grassetto"))
			var ob = OptionButton.new()
			ob.custom_minimum_size.x = 260
			ob.add_item("- in attesa -")
			var uids = giocatori.keys()
			for u in uids:
				ob.add_item(giocatori[u])
			var cur: String = assegna.get(a["id"], "")
			ob.selected = uids.find(cur) + 1 if cur != "" else 0
			var id: int = a["id"]
			ob.item_selected.connect(func(k): assegna[id] = uids[k - 1] if k > 0 else "")
			hh.add_child(ob)
			elenco.add_child(hh)
	ridisegna.call()
	var ev = func(e: Dictionary):
		match e.get("e"):
			"stanza":
				lbl_url.text = "Codice stanza: %s\n%s" % [e["codice"], e["url"]]
				qr.imposta(rete.qr(e["url"]))
			"entra":
				giocatori[e["uid"]] = e.get("nome", "Pilota")
				# assegna da solo il primo aereo libero
				for a in R.S["aerei"]:
					if a["controllo"] == "telefono" and assegna.get(a["id"], "") == "":
						if not assegna.values().has(e["uid"]):
							assegna[a["id"]] = e["uid"]
				ridisegna.call()
			"errore":
				lbl_url.text = "Problema con la rete: " + str(e.get("msg", ""))
	rete.evento.connect(ev)
	rete.avvia()
	if not rete.web:
		lbl_url.text = "La stanza per i telefoni si apre solo nella versione web del gioco."
	var hb = HBoxContainer.new()
	v.add_child(hb)
	hb.add_child(Tema.bottone("Indietro", func(): rete.evento.disconnect(ev); rete.chiudi(); schermaglia(), 22))
	hb.add_child(Tema.bottone("Si parte!", func():
		for a in R.S["aerei"]:
			if a["controllo"] == "telefono":
				var u: String = assegna.get(a["id"], "")
				if u == "":
					a["controllo"] = "ia"
				else:
					a["uid"] = u
					a["giocatore"] = giocatori.get(u, "")
		rete.evento.disconnect(ev)
		principale.avvia_partita(R, {"livelli": {"G": opz_ia, "A": opz_ia}, "veloce": veloce}), 28, 240))

# --------------------------------------------------------------------------- pagina online
func online() -> void:
	_pulisci()
	var v = _colonna(1200)
	v.add_child(Tema.titolo("Online e telefoni", 52, Tema.ROSSO))
	v.add_child(Tema.etichetta("Si gioca a distanza in due modi, anche insieme: con il gioco completo su un altro computer o iPad, oppure dal telefono (la «cloche»: manovre e raffiche in segreto, con una piccola mappa). Chi crea la partita fa da tabellone: vede il cielo in 3D e un QR code con il codice della stanza.", 20, Tema.SEPPIA, "testo", 1140))
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	v.add_child(h)
	h.add_child(_carta("res://assets/img/scenari/s9.webp", "Crea una partita", "Ospiti tu", "Scegli lo scenario nel generatore: in «Giochi con» indica chi entra da fuori (amici online o telefoni). Poi compare il QR code con il codice della stanza.", 370,
		func(): gen["chi"] = 3; generatore(), false, 470))
	h.add_child(_carta("res://assets/img/scenari/s2.webp", "Entra con il gioco completo", "Da un altro computer o iPad", "Scrivi il codice di 4 lettere che vedi sullo schermo di chi ospita: giochi con il tuo aereo in 3D.", 370, entra_online, false, 470))
	h.add_child(_carta("res://assets/img/scenari/s7.webp", "Gioca dal telefono", "Smartphone", "Inquadra con la fotocamera il QR code sullo schermo di chi ospita, scrivi il tuo nome e pilota dal telefono. Senza QR: apri la pagina «telefono.html» del gioco e scrivi il codice.", 370, func(): pass, false, 470))
	v.add_child(Tema.etichetta("Anche gli scenari storici e la schermaglia libera (aereo per aereo: «Online o telefono») possono avere piloti da fuori.", 18, Tema.SEPPIA, "testo", 1140))
	v.add_child(Tema.bottone("Indietro", principale_menu, 22))

# --------------------------------------------------------------------------- ospite online
func entra_online() -> void:
	_pulisci()
	var v := _colonna(760)
	v.add_child(Tema.titolo("Entra in una partita online", 44, Tema.ROSSO))
	v.add_child(Tema.etichetta("Chiedi il codice di 4 lettere a chi ospita la partita (lo vede nella schermata «Partita online e telefoni»).", 20, Tema.SEPPIA, "testo", 700))
	var g := GridContainer.new()
	g.columns = 2
	v.add_child(g)
	g.add_child(Tema.etichetta("Codice", 22, Tema.INCHIOSTRO, "grassetto"))
	var cod := LineEdit.new()
	cod.max_length = 4
	cod.custom_minimum_size.x = 200
	g.add_child(cod)
	g.add_child(Tema.etichetta("Il tuo nome", 22, Tema.INCHIOSTRO, "grassetto"))
	var nome := LineEdit.new()
	nome.max_length = 16
	nome.text = principale.rete.carica("bluemax_nome")
	nome.custom_minimum_size.x = 300
	g.add_child(nome)
	var stato := Tema.etichetta("", 20, Tema.ROSSO, "testo", 700)
	v.add_child(stato)
	var rete: Rete = principale.rete
	var ev := func(e: Dictionary):
		match e.get("e"):
			"dentro":
				stato.text = "Sei nella stanza %s: aspetta che chi ospita faccia partire la partita." % e.get("codice", "")
			"errore":
				stato.text = str(e.get("msg", "Errore di rete"))
			"stato":
				var d = JSON.parse_string(str(e.get("j", "")))
				if d is Dictionary and d.has("S"):
					principale.avvia_ospite(d["S"], int(d.get("anim", {}).get("seq", 0)))
	rete.evento.connect(ev)
	tree_exiting.connect(func():
		if rete.evento.is_connected(ev):
			rete.evento.disconnect(ev))
	var h := HBoxContainer.new()
	v.add_child(h)
	h.add_child(Tema.bottone("Indietro", func(): rete.chiudi(); principale_menu(), 22))
	h.add_child(Tema.bottone("Entra", func():
		if not rete.web:
			stato.text = "La partita online funziona nella versione web del gioco."
			return
		rete.salva("bluemax_nome", nome.text.strip_edges())
		stato.text = "Mi collego..."
		rete.entra(cod.text.strip_edges().to_upper(), nome.text.strip_edges() if nome.text.strip_edges() != "" else "Pilota"), 26, 200))

# --------------------------------------------------------------------------- crediti
func crediti() -> void:
	_pulisci()
	var v = _colonna(1000)
	v.add_child(Tema.titolo("Crediti", 52, Tema.ROSSO))
	var t = RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.custom_minimum_size = Vector2(940, 0)
	t.text = """[b]Blue Max[/b] - gioco ideato da Phil Hall, sviluppato da John Harshman (1983) e Marc W. Miller (1989), GDW. Copertina di Steve Venters, mappa di Thierry Monter. Edizione italiana Stratelibri (1993) a cura di Alberto Capietti, traduzione di Dario Benedetti.

Conversione digitale per uso personale di Stefano, dal suo gioco originale: regolamento, Tabelle-Movimento, pedine e mappa scansionati e trascritti.

[b]Modelli 3D[/b] (Sketchfab, licenza CC Attribution): serie «Red Baron Arcade» di NCTKM (Albatros D.III e D.V, Fokker Dr.I e D.VII, Pfalz D.III, Siemens-Schuckert D.III, Nieuport 17, Sopwith Camel, Sopwith Triplane); Halberstadt CL.II di Albert_Limeres; Bristol F2B di thomasvansteelandt; RAF S.E.5 di helijah; SPAD XIII di BrusselseWafel; Spad S VII di manilov.ap; Nieuport 28 di ThomasBoone.

[b]Illustrazioni[/b] della copertina e del menu generate con Kling AI.
[b]Caratteri[/b]: IM Fell English SC (Igino Marini), Oswald (Vernon Adams), Special Elite (Astigmatic), licenze SIL OFL e Apache.
Motore: Godot Engine."""
	v.add_child(t)
	v.add_child(Tema.bottone("Indietro", principale_menu, 22))


class QR extends Control:
	var bit = ""
	func imposta(s: String) -> void:
		bit = s
		queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
		if bit == "":
			return
		var n = int(sqrt(bit.length()))
		if n <= 0:
			return
		var l = (minf(size.x, size.y) - 20) / n
		for y in n:
			for x in n:
				if bit[y * n + x] == "1":
					draw_rect(Rect2(10 + x * l, 10 + y * l, ceilf(l), ceilf(l)), Color.BLACK)
