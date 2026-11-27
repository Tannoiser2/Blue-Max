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

func principale_menu() -> void:
	_pulisci()
	var v = _colonna(560)
	v.add_child(Tema.titolo("Blue Max", 96, Tema.ROSSO))
	v.add_child(Tema.etichetta("Duelli aerei nel cielo di Francia, 1917-1918", 26, Tema.SEPPIA, "documento"))
	var sal = ""
	if principale.rete:
		sal = principale.rete.carica("bluemax_partita")
	if sal != "":
		v.add_child(Tema.bottone("Riprendi la partita", _riprendi.bind(sal), 28))
	v.add_child(Tema.bottone("Tutorial: impara a volare", _tutorial, 28))
	v.add_child(Tema.bottone("Scenari storici", scenari, 28))
	v.add_child(Tema.bottone("Schermaglia libera", schermaglia, 28))
	v.add_child(Tema.bottone("Entra in una partita online", entra_online, 28))
	v.add_child(Tema.bottone("Campagna", _campagna, 28))
	v.add_child(Tema.bottone("Regolamento", func(): add_child(Regolamento.new()), 28))
	v.add_child(Tema.bottone("Crediti", crediti, 28))
	var nota = Tema.etichetta("Gioco originale GDW (1983), edizione italiana Stratelibri (1993). Conversione digitale per uso personale.", 16, Tema.SEPPIA, "testo", 500)
	v.add_child(nota)

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
func scenari() -> void:
	_pulisci()
	var v = _colonna(900)
	v.add_child(Tema.titolo("Scenari storici", 52, Tema.ROSSO))
	var lato = {"v": "A"}
	var h = HBoxContainer.new()
	v.add_child(h)
	h.add_child(Tema.etichetta("Giochi con:", 22, Tema.INCHIOSTRO, "grassetto"))
	var ob = OptionButton.new()
	for t in ["gli Alleati", "i Tedeschi", "entrambi (due giocatori)", "nessuno: guardo il computer"]:
		ob.add_item(t)
	ob.custom_minimum_size.x = 340
	h.add_child(ob)
	h.add_child(Tema.etichetta("Avversario:", 22, Tema.INCHIOSTRO, "grassetto"))
	var oi = _scelta_ia()
	h.add_child(oi)
	for s in Scenari.ELENCO:
		var p = Tema.pannello(Color("f3ead6"), Tema.SEPPIA, 12)
		var vv = VBoxContainer.new()
		p.add_child(vv)
		vv.add_child(Tema.etichetta(s["titolo"], 26, Tema.INCHIOSTRO, "titolo"))
		vv.add_child(Tema.etichetta(s["testo"], 19, Tema.SEPPIA, "testo", 820))
		var id: String = s["id"]
		vv.add_child(Tema.bottone("Gioca", func():
			var c = {"G": "ia", "A": "ia"}
			match ob.selected:
				0: c["A"] = "umano"
				1: c["G"] = "umano"
				2:
					c["A"] = "umano"
					c["G"] = "umano"
			var R = Scenari.costruisci(id, c, {"seme": randi()})
			for a in R.S["aerei"]:
				if a["controllo"] == "umano" and ob.selected == 2:
					a["giocatore"] = "Alleati" if a["lato"] == "A" else "Tedeschi"
			principale.avvia_partita(R, {"livelli": {"G": opz_ia, "A": opz_ia}}), 22, 200))
		v.add_child(p)
	v.add_child(Tema.bottone("Indietro", principale_menu, 22))

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
	ho.add_child(Tema.etichetta("Regole opzionali:", 21, Tema.INCHIOSTRO, "grassetto"))
	for o in [["togli_pilota_ucciso", "Togli la pedina «Pilota ucciso» (consigliato)"], ["danni_visibili", "Danni dei nemici visibili"], ["carburante_meta", "Carburante dimezzato"],
			["tabella_corretta", "Tabella di combattimento corretta GDW"], ["collisioni", "Collisioni in volo"], ["coda_piu_uno", "Una casella di coda in più"],
			["tiro_vite", "Tiro su aereo in avvitamento -2"], ["osservatore_limitato", "Osservatore spara solo in volo dritto"]]:
		var cb = CheckBox.new()
		cb.text = o[1]
		cb.button_pressed = opzioni_partita[o[0]]
		var k: String = o[0]
		cb.toggled.connect(func(x): opzioni_partita[k] = x)
		ho.add_child(cb)
	var cv = CheckBox.new()
	cv.text = "Animazioni veloci"
	cv.button_pressed = veloce
	cv.toggled.connect(func(x): veloce = x)
	ho.add_child(cv)
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
	g.add_child(on)
	var oa = OptionButton.new()
	var tipi = _aerei_di(x["nazione"])
	for t in tipi:
		var nome: String = Dati.aerei[t]["nome"]
		oa.add_item(nome)
	oa.selected = maxi(0, tipi.find(x["tipo"]))
	oa.custom_minimum_size.x = 250
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
