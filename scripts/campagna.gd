class_name Campagna
extends Control
## Il gioco campagna: da gennaio 1917 a novembre 1918, quattro missioni al mese.
## Il pilota accumula esperienza e abilità, cambia aereo quando ne arrivano di nuovi,
## può morire o finire prigioniero. Salvataggio su Firebase con un codice di 6 lettere.

const MESI := ["Gennaio", "Febbraio", "Marzo", "Aprile", "Maggio", "Giugno", "Luglio", "Agosto", "Settembre", "Ottobre", "Novembre", "Dicembre"]
const SOGLIE := [100, 200, 350, 500, 1000]
var menu
var C: Dictionary = {}
var v: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if C.is_empty():
		inizio()

static func data(mese: int, sett := 0) -> String:
	return "%s settimana, %s %d" % [["1ª", "2ª", "3ª", "4ª"][sett], MESI[mese % 12], 1917 + mese / 12]

func _pagina(t: String, larg := 1100) -> VBoxContainer:
	for c in get_children():
		c.queue_free()
	var cc = CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var p = Tema.pannello(Color(0.93, 0.89, 0.79, 0.97), Tema.SEPPIA, 22)
	p.custom_minimum_size = Vector2(larg, 0)
	cc.add_child(p)
	var sc = ScrollContainer.new()
	sc.custom_minimum_size = Vector2(larg - 40, minf(900, get_viewport_rect().size.y - 140))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(sc)
	v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	v.add_child(Tema.titolo(t, 48, Tema.ROSSO))
	return v

func _salvati() -> Array:
	var s: String = menu.principale.rete.carica("bluemax_campagne")
	var l = JSON.parse_string(s) if s != "" else []
	return l if l is Array else []

func inizio() -> void:
	_pagina("Campagna")
	v.add_child(Tema.etichetta("Una serie di missioni collegate, dal gennaio 1917 alla fine della guerra. Il tuo pilota comincia novellino: ogni turno in volo vale 1 punto d'esperienza, ogni abbattimento 25. Con l'esperienza arrivano le abilità; con cinque abbattimenti diventi un Asso. Se vieni abbattuto, il tuo rimpiazzo sarà un novellino.", 20, Tema.SEPPIA, "testo", 1040))
	var sal = _salvati()
	if not sal.is_empty():
		v.add_child(Tema.etichetta("Campagne su questo dispositivo", 26, Tema.INCHIOSTRO, "titolo"))
		for x in sal:
			var codice: String = x.get("codice", "")
			v.add_child(Tema.bottone("%s - %s (%s)" % [x.get("pilota", ""), data(int(x.get("mese", 0)), int(x.get("settimana", 0))), codice], func(): _carica(codice), 20))
	var h = HBoxContainer.new()
	v.add_child(h)
	h.add_child(Tema.etichetta("Riprendi con il codice:", 22, Tema.INCHIOSTRO, "grassetto"))
	var le = LineEdit.new()
	le.custom_minimum_size.x = 200
	le.max_length = 6
	h.add_child(le)
	h.add_child(Tema.bottone("Carica", func(): _carica(le.text.strip_edges().to_upper()), 20))
	v.add_child(HSeparator.new())
	v.add_child(Tema.etichetta("Nuova campagna", 30, Tema.INCHIOSTRO, "titolo"))
	var g = GridContainer.new()
	g.columns = 2
	v.add_child(g)
	g.add_child(Tema.etichetta("Nome del pilota", 21, Tema.INCHIOSTRO, "grassetto"))
	var nome = LineEdit.new()
	nome.text = "Stefano"
	nome.custom_minimum_size.x = 360
	g.add_child(nome)
	g.add_child(Tema.etichetta("Nazione", 21, Tema.INCHIOSTRO, "grassetto"))
	var on = OptionButton.new()
	var naz = ["inghilterra", "francia", "usa", "germania"]
	for n in naz:
		on.add_item(Dati.NAZIONI[n]["nome"])
	g.add_child(on)
	g.add_child(Tema.etichetta("Inizio", 21, Tema.INCHIOSTRO, "grassetto"))
	var om = OptionButton.new()
	for m in 23:
		om.add_item("%s %d" % [MESI[m % 12], 1917 + m / 12])
	g.add_child(om)
	g.add_child(Tema.etichetta("Gregari (computer)", 21, Tema.INCHIOSTRO, "grassetto"))
	var og = OptionButton.new()
	for k in ["Nessuno", "Uno", "Due"]:
		og.add_item(k)
	og.selected = 1
	g.add_child(og)
	g.add_child(Tema.etichetta("Nemici", 21, Tema.INCHIOSTRO, "grassetto"))
	var oi = OptionButton.new()
	for k in ["Recluta", "Veterano", "Asso"]:
		oi.add_item(k)
	oi.selected = 1
	g.add_child(oi)
	var hb = HBoxContainer.new()
	v.add_child(hb)
	hb.add_child(Tema.bottone("Indietro", func(): menu.principale_menu(), 22))
	hb.add_child(Tema.bottone("Arruolati", func():
		var n: String = naz[on.selected]
		C = {"codice": _codice(), "nazione": n, "lato": Dati.NAZIONI[n]["lato"], "mese": om.selected, "settimana": 0,
			"gregari": og.selected, "livello": ["recluta", "veterano", "asso"][oi.selected], "caduti": [],
			"pilota": _nuovo_pilota(nome.text.strip_edges() if nome.text.strip_edges() != "" else "Pilota"), "registro": []}
		C["pilota"]["aereo"] = _aerei_disponibili()[0]
		_salva()
		scheda_volo(), 26))

func _codice() -> String:
	var l = "ABCDEFGHJKLMNPQRSTUVWXYZ"
	var s = ""
	for i in 6:
		s += l[randi() % l.length()]
	return s

func _nuovo_pilota(n: String) -> Dictionary:
	return {"nome": n, "esperienza": 0, "abbattimenti": 0, "abilita": [], "voli": [], "aereo": ""}

func _aerei_disponibili() -> Array:
	var mese: int = C["mese"]
	var naz: String = C["nazione"]
	var l = Dati.ordine_aerei.filter(func(t): return naz in Dati.aerei[t]["nazioni"] and int(Dati.aerei[t]["disponibile_dal"]) <= mese and int(Dati.aerei[t]["osservatore"]) == 0)
	if naz == "usa" and l.is_empty():
		l = ["nieuport17", "spad7"]
	l.sort_custom(func(a, b): return int(Dati.aerei[a]["disponibile_dal"]) > int(Dati.aerei[b]["disponibile_dal"]))
	return l

func _carica(codice: String) -> void:
	if codice.length() != 6:
		return
	var rete: Rete = menu.principale.rete
	var loc: String = rete.carica("bluemax_campagna_" + codice)
	if loc != "":
		C = JSON.parse_string(loc)
		scheda_volo()
		return
	_pagina("Carico la campagna %s..." % codice)
	var cb = func(e: Dictionary):
		if e.get("e") == "campionato" and e.get("codice") == codice:
			var d = JSON.parse_string(str(e.get("dati", ""))) if str(e.get("dati", "")) != "" else null
			if d is Dictionary:
				C = d
				scheda_volo()
			else:
				_pagina("Campagna non trovata")
				v.add_child(Tema.bottone("Indietro", inizio, 22))
	rete.evento.connect(cb, CONNECT_ONE_SHOT)
	rete.chiedi_campionato(codice)
	if not rete.web:
		_pagina("Campagna non trovata su questo dispositivo")
		v.add_child(Tema.bottone("Indietro", inizio, 22))

func _salva() -> void:
	var rete: Rete = menu.principale.rete
	var j = JSON.stringify(C)
	rete.salva("bluemax_campagna_" + C["codice"], j)
	rete.salva_campionato(C["codice"], j)
	var sal = _salvati().filter(func(x): return x.get("codice") != C["codice"])
	sal.push_front({"codice": C["codice"], "pilota": C["pilota"]["nome"], "mese": C["mese"], "settimana": C["settimana"]})
	rete.salva("bluemax_campagne", JSON.stringify(sal.slice(0, 8)))

func _anzianita(p: Dictionary) -> String:
	if int(p["abbattimenti"]) >= 5:
		return "Asso"
	return "Veterano" if int(p["esperienza"]) >= 50 else "Novellino"

## La Scheda di Volo del pilota (come quella stampata) e la prossima missione
func scheda_volo() -> void:
	_pagina("Scheda di Volo", 1240)
	var p: Dictionary = C["pilota"]
	v.add_child(Tema.etichetta("Campagna %s - codice [%s] per riprenderla da qualsiasi dispositivo" % [data(C["mese"], C["settimana"]), C["codice"]], 20, Tema.SEPPIA, "documento", 1180))
	var g = GridContainer.new()
	g.columns = 6
	v.add_child(g)
	for x in [["Nome", p["nome"]], ["Nazionalità", Dati.NAZIONI[C["nazione"]]["nome"]], ["Anzianità", _anzianita(p)],
		["Esperienza", str(p["esperienza"])], ["Abbattimenti", str(p["abbattimenti"])], ["Aereo", Dati.aerei[p["aereo"]]["nome"]]]:
		g.add_child(Tema.etichetta(x[0] + ":", 20, Tema.SEPPIA, "grassetto"))
		var l = Tema.etichetta(x[1], 22, Tema.INCHIOSTRO, "documento")
		l.custom_minimum_size.x = 170
		g.add_child(l)
	var ab = ", ".join(p["abilita"].map(func(k): return Dati.ABILITA[k]["nome"]))
	v.add_child(Tema.etichetta("Abilità speciali: " + (ab if ab != "" else "nessuna"), 21, Tema.INCHIOSTRO, "testo", 1180))
	# tabella dei voli
	var t = GridContainer.new()
	t.columns = 6
	v.add_child(t)
	for h in ["Volo", "Settimana/Anno", "Aereo", "Tempo di volo", "Abbattimenti", "Esperienza"]:
		var l = Tema.etichetta(h, 18, Tema.ROSSO, "grassetto")
		l.custom_minimum_size.x = 150
		t.add_child(l)
	var voli: Array = p["voli"]
	for i in voli.size():
		var vv: Dictionary = voli[i]
		for x in [str(i + 1), vv["data"], vv["aereo"], "%d turni" % int(vv["turni"]), str(vv["abbattimenti"]), "+%d" % int(vv["esperienza"])]:
			t.add_child(Tema.etichetta(x, 18, Tema.INCHIOSTRO, "documento"))
	if not C["caduti"].is_empty():
		v.add_child(Tema.etichetta("Caduti e prigionieri: " + ", ".join(C["caduti"]), 19, Tema.SEPPIA, "testo", 1180))
	# cambio d'aereo
	var disp = _aerei_disponibili()
	if disp.size() > 1:
		var h = HBoxContainer.new()
		v.add_child(h)
		h.add_child(Tema.etichetta("Aereo per la prossima missione:", 21, Tema.INCHIOSTRO, "grassetto"))
		var oa = OptionButton.new()
		for x in disp:
			oa.add_item(Dati.aerei[x]["nome"])
		oa.selected = maxi(0, disp.find(p["aereo"]))
		oa.item_selected.connect(func(k): p["aereo"] = disp[k]; _salva())
		h.add_child(oa)
	if int(C["mese"]) >= 23:
		v.add_child(Tema.titolo("L'armistizio è firmato: la guerra è finita!", 34, Tema.VERDE))
	var hb = HBoxContainer.new()
	v.add_child(hb)
	hb.add_child(Tema.bottone("Menu", func(): menu.principale_menu(), 22))
	if int(C["mese"]) < 23:
		hb.add_child(Tema.bottone("Decolla per la missione", missione, 26))

func missione() -> void:
	var rn = RandomNumberGenerator.new()
	rn.randomize()
	var p: Dictionary = C["pilota"]
	var territorio = "alleato" if rn.randi_range(1, 6) <= 3 else "tedesco"
	var lista = []
	var naz: String = C["nazione"]
	lista.append({"tipo": p["aereo"], "nazione": naz, "controllo": "umano", "quota": rn.randi_range(1, 3),
		"pilota": {"nome": p["nome"], "abilita": p["abilita"], "abbattimenti": p["abbattimenti"], "novellino": int(p["esperienza"]) < 50, "esperienza": p["esperienza"]}})
	var disp = _aerei_disponibili()
	for i in int(C["gregari"]):
		lista.append({"tipo": disp[rn.randi_range(0, disp.size() - 1)], "nazione": naz, "controllo": "ia", "quota": 2,
			"pilota": {"nome": ["Gregario Rossi", "Gregario Bianchi"][i], "novellino": rn.randf() < 0.4}})
	var lato_nemico = "G" if C["lato"] == "A" else "A"
	var nemici_naz = ["germania"] if lato_nemico == "G" else ["inghilterra", "francia"] + (["usa"] if C["mese"] >= 15 else [])
	var n_nem = 1 + int(C["gregari"]) + (1 if rn.randf() < 0.3 else 0)
	var mese: int = C["mese"]
	for i in n_nem:
		var nn: String = nemici_naz[rn.randi_range(0, nemici_naz.size() - 1)]
		var tipi = Dati.ordine_aerei.filter(func(t): return nn in Dati.aerei[t]["nazioni"] and int(Dati.aerei[t]["disponibile_dal"]) <= mese)
		if tipi.is_empty():
			tipi = ["albatros_d3"] if nn == "germania" else ["nieuport17"]
		var asso = rn.randf() < 0.12
		lista.append({"tipo": tipi[rn.randi_range(0, tipi.size() - 1)], "nazione": nn, "controllo": "ia", "quota": rn.randi_range(1, 3),
			"pilota": {"nome": "Pilota nemico %d" % (i + 1) if not asso else "Asso nemico", "novellino": rn.randf() < 0.35 and not asso, "abbattimenti": 7 if asso else 0, "abilita": ["bonus_tiro", "mira"] if asso else []}})
	var R = Scenari.schermaglia(lista, {"seme": rn.randi(), "togli_pilota_ucciso": true}, true)
	R.S["territorio"] = territorio
	# in territorio nemico la linea delle trincee pesa di più: si combatte sopra le sue linee
	C["in_corso"] = {"data": data(C["mese"], C["settimana"]), "territorio": territorio}
	_salva()
	menu.principale.avvia_partita(R, {"livelli": {"G": C["livello"], "A": C["livello"]}, "campagna": C})

## Dopo la missione: esperienza, abbattimenti, sorte del pilota, nuove abilità
func fine_missione(camp: Dictionary, R: Regole, turni: int) -> void:
	C = camp
	var p: Dictionary = C["pilota"]
	var io = {}
	for a in R.S["aerei"]:
		if a["controllo"] == "umano":
			io = a
	var rn = RandomNumberGenerator.new()
	rn.randomize()
	var esp = turni + 25 * int(io.get("abbattimenti", 0))
	var esito = ""
	var morto = false
	var prigioniero = false
	if io.get("stato", "") in ["abbattuto", "catturato"]:
		var ucciso = false
		for d in io.get("danni_visti", []):
			if d.get("spec", "") in ["pilota_ucciso", "esplosione"]:
				ucciso = true
		if ucciso:
			morto = true
			esito = "Il tuo pilota è caduto in combattimento."
		elif R.territorio_amico(io) and io["stato"] == "abbattuto":
			var d = rn.randi_range(1, 6)
			if d == 1:
				morto = true
				esito = "Abbattuto in territorio amico: il pilota non sopravvive all'impatto."
			else:
				esito = "Abbattuto in territorio amico: il pilota torna alla sua unità, senza aereo e disarmato."
		else:
			var d = rn.randi_range(1, 6)
			if d == 1:
				morto = true
				esito = "Abbattuto oltre le linee: il pilota muore."
			elif d >= 4:
				esito = "Abbattuto oltre le linee, ma riesce a non farsi catturare e torna al suo aeroporto!"
			else:
				prigioniero = true
				esito = "Abbattuto oltre le linee: catturato, finisce in un campo di prigionia."
	else:
		esito = "Rientro alla base."
	p["voli"].append({"data": C.get("in_corso", {}).get("data", ""), "aereo": Dati.aerei[p["aereo"]]["nome"], "turni": turni, "abbattimenti": int(io.get("abbattimenti", 0)), "esperienza": esp})
	var prima: int = int(p["esperienza"])
	var prima_abb: int = int(p["abbattimenti"])
	p["esperienza"] = prima + esp
	p["abbattimenti"] = prima_abb + int(io.get("abbattimenti", 0))
	var nuove = 0
	for s in SOGLIE:
		if prima < s and int(p["esperienza"]) >= s:
			nuove += 1
	if prima_abb < 5 and int(p["abbattimenti"]) >= 5:
		nuove += 1
	C["settimana"] = int(C["settimana"]) + 1
	if int(C["settimana"]) >= 4:
		C["settimana"] = 0
		C["mese"] = int(C["mese"]) + 1
	C.erase("in_corso")
	_pagina("Rapporto della missione")
	v.add_child(Tema.etichetta(esito, 24, Tema.INCHIOSTRO, "documento", 1040))
	v.add_child(Tema.etichetta("Tempo di volo %d turni, abbattimenti %d: +%d punti d'esperienza (totale %d)." % [turni, int(io.get("abbattimenti", 0)), esp, int(p["esperienza"])], 21, Tema.INCHIOSTRO, "testo", 1040))
	if morto or prigioniero:
		C["caduti"].append("%s (%s)" % [p["nome"], "caduto" if morto else "prigioniero"])
		var nuovo = _nuovo_pilota("%s II" % p["nome"].split(" ")[0])
		nuovo["aereo"] = _aerei_disponibili()[0]
		C["pilota"] = nuovo
		v.add_child(Tema.etichetta("Al suo posto arriva un novellino: %s." % nuovo["nome"], 21, Tema.ROSSO, "testo", 1040))
		_salva()
		v.add_child(Tema.bottone("Scheda di Volo", scheda_volo, 24))
		return
	_salva()
	if nuove > 0:
		_scegli_abilita(nuove)
	else:
		v.add_child(Tema.bottone("Scheda di Volo", scheda_volo, 24))

func _scegli_abilita(n: int) -> void:
	var p: Dictionary = C["pilota"]
	v.add_child(Tema.etichetta("Nuova abilità speciale! Scegline una:", 26, Tema.VERDE, "titolo"))
	var asso = int(p["abbattimenti"]) >= 5
	for k in Dati.ABILITA:
		if k in p["abilita"]:
			continue
		if k in ["mira", "portata"] and not asso:
			continue
		var x: Dictionary = Dati.ABILITA[k]
		var h = HBoxContainer.new()
		var b = Tema.bottone(x["nome"], func():
			p["abilita"].append(k)
			_salva()
			if n > 1:
				_pagina("Ancora un'abilità")
				_scegli_abilita(n - 1)
			else:
				scheda_volo(), 20, 260)
		h.add_child(b)
		h.add_child(Tema.etichetta(x["testo"], 19, Tema.SEPPIA, "testo", 760))
		v.add_child(h)
