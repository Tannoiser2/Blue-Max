class_name Gioco
extends Control
## La partita: segue le 10 fasi del turno, chiede le scelte ai piloti (persone, computer o telefoni),
## anima movimenti, raffiche, pedine-danno e abbattimenti, registra tutto per il replay finale.

signal uscita
signal scelta_fatta(m: Dictionary)
signal fuoco_fatto(l: Array)
signal avanti

var R: Regole
var mondo: Mondo
var rete: Rete
var ia = {}
var livelli = {"G": "veterano", "A": "veterano"}
var tutorial: Tutorial = null
var veloce = false
var storia = []
var turno_corrente = {}
var in_replay = false
var nome_salvataggio = "bluemax_partita"
var campagna: Dictionary = {}
var dal_telefono = {}       # id aereo -> scelta arrivata dal telefono
var ospite = false            # partita online vista da un altro computer
var ultimo_anim = {}          # l'ultimo turno giocato, per far rivedere i movimenti all'ospite
var coda_ospite = []
var ospite_occupato = false
var risposto = ""
var anim_seq = 0
var anim_visto = 0
var richieste_tel = {}      # id aereo -> {tipo, opzioni}

# interfaccia
var barra_fasi: HBoxContainer
var lbl_turno: Label
var lbl_fase: Label
var scheda: SchedaAereo
var miniatura: VistaDanni
var bt_scheda: Button
var bt_miniatura: Button
var lista_aerei: VBoxContainer
var pannello_azione: PanelContainer
var titolo_azione: Label
var corpo_azione: VBoxContainer
var bottoni_azione: HBoxContainer
var banner: Label
var velo: ColorRect
var modale: Control
var overlay3d: Control
var diario: RichTextLabel
var pannello_diario: PanelContainer
var aereo_mostrato = -1
var sinistra: PanelContainer
var destra: PanelContainer

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func avvia(regole: Regole, m: Mondo, r: Rete, opz := {}) -> void:
	R = regole
	mondo = m
	rete = r
	livelli = opz.get("livelli", livelli)
	veloce = opz.get("veloce", false)
	campagna = opz.get("campagna", {})
	ia["G"] = IA.new(R, livelli.get("G", "veterano"))
	ia["A"] = IA.new(R, livelli.get("A", "veterano"))
	_costruisci()
	mondo.R = R
	mondo.imposta_overlay(overlay3d)
	mondo.crea_aerei()
	mondo.aereo_toccato.connect(_aereo_toccato)
	mondo.cella_toccata.connect(_cella_toccata)
	if rete:
		rete.evento.connect(_evento_rete)
	_centra_inizio()
	mostra_aereo(_primo_umano())
	_aggiorna_lista()
	if opz.get("tutorial", null) != null:
		tutorial = opz["tutorial"]
		tutorial.gioco = self
		add_child(tutorial)
	await get_tree().process_frame
	ciclo()

## Partita online vista da un altro computer: lo stato arriva da chi ospita, le scelte partono da qui
func avvia_ospite(S: Dictionary, m: Mondo, r: Rete, seq := 0) -> void:
	ospite = true
	anim_visto = seq
	R = Regole.new(S)
	mondo = m
	rete = r
	_costruisci()
	mondo.R = R
	mondo.imposta_overlay(overlay3d)
	mondo.crea_aerei()
	mondo.aereo_toccato.connect(_aereo_toccato)
	rete.evento.connect(_evento_ospite)
	_centra_inizio()
	var mio = _mio_online()
	mostra_aereo(mio["id"] if not mio.is_empty() else 0)
	_aggiorna_lista()
	_aggiorna_fasi(int(R.S.get("fase", 0)))
	annuncia("Sei collegato alla partita online", 3.0)

func _mio_online() -> Dictionary:
	for a in R.S["aerei"]:
		if a["controllo"] == "telefono" and a["uid"] == rete.uid:
			return a
	return {}

func _evento_ospite(e: Dictionary) -> void:
	if e.get("e") != "stato":
		return
	var d = JSON.parse_string(str(e.get("j", "")))
	if d is Dictionary and d.has("S"):
		coda_ospite.append(d)
		if not ospite_occupato:
			_elabora_ospite()

func _elabora_ospite() -> void:
	ospite_occupato = true
	while not coda_ospite.is_empty():
		var d: Dictionary = coda_ospite.pop_front()
		# se ne sono arrivati altri, basta l'ultimo (ma senza perdere l'animazione del turno)
		var anim: Dictionary = Regole.interi(d.get("anim", {}))
		if not anim.is_empty() and int(anim.get("seq", 0)) > anim_visto:
			anim_visto = int(anim["seq"])
			_pulisci_azione("")
			await _anima_turno(R, anim, 1.6)
		R = Regole.new(d["S"])
		mondo.R = R
		mondo.crea_aerei()
		_aggiorna_lista()
		_aggiorna_fasi(int(R.S.get("fase", 0)))
		mostra_aereo(aereo_mostrato if aereo_mostrato >= 0 else 0)
		_aggiorna_diario()
		var mio = _mio_online()
		var rich: Dictionary = d.get("richieste", {})
		if not mio.is_empty() and rich.has(str(mio["id"])):
			var rq: Dictionary = rich[str(mio["id"])]
			var chiave = "%d-%s" % [int(R.S["turno"]), rq["tipo"]]
			if chiave != risposto and coda_ospite.is_empty():
				risposto = chiave
				Suoni.suona("avviso")
				var auto = rete.parametri().has("auto")
				if auto:
					var ia_o = IA.new(R, "veterano")
					if rq["tipo"] == "manovra":
						var m0 = ia_o.scegli_manovra(mio, {})
						rete.azione("manovra", {"id": mio["id"], "codice": m0["codice"], "quota": int(m0["quota"])})
					else:
						rete.azione("fuoco", {"id": mio["id"], "lista": ia_o.scegli_attacchi(mio).map(func(x): return {"a": x["a"], "arma": x["arma"], "raffica": x["raffica"]})})
					print("OSPITE risponde ", rq["tipo"], " turno ", R.S["turno"])
				elif rq["tipo"] == "manovra":
					var m = await _scelta_umana(mio, {}, str(rq.get("info", "")))
					rete.azione("manovra", {"id": mio["id"], "codice": m["codice"], "quota": int(m["quota"])})
				else:
					var l = await _fuoco_umano(mio)
					rete.azione("fuoco", {"id": mio["id"], "lista": l.map(func(x): return {"a": x["a"], "arma": x["arma"], "raffica": x["raffica"]})})
				_pulisci_azione("In attesa degli altri piloti")
		if d.get("finita", false):
			annuncia("Fine del combattimento", 4.0)
	ospite_occupato = false

func _primo_umano() -> int:
	for a in R.S["aerei"]:
		if a["controllo"] == "umano":
			return a["id"]
	return 0

func _centra_inizio() -> void:
	var s = Vector3.ZERO
	var n = 0
	var mn = Vector3(1e9, 0, 1e9)
	var mx = Vector3(-1e9, 0, -1e9)
	for a in R.attivi():
		var p = mondo.mondo_da_cella(R.pos(a))
		s += p
		mn = mn.min(p)
		mx = mx.max(p)
		n += 1
	if n > 0:
		mondo.centra_su(s / n, clampf((mx - mn).length() * 1.5 + 6.0, 12.0, 30.0))
		mondo.pitch_dest = 55.0
		mondo.yaw_dest = 0.0

# --------------------------------------------------------------------------- costruzione dell'interfaccia
func _costruisci() -> void:
	overlay3d = Control.new()
	overlay3d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay3d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay3d)
	# barra in alto
	var alto = Tema.pannello_scuro(8)
	alto.set_anchors_preset(Control.PRESET_TOP_WIDE)
	alto.offset_bottom = 64
	add_child(alto)
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	alto.add_child(hb)
	var tit = Tema.titolo("Blue Max", 34, Tema.ORO)
	tit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tit.custom_minimum_size.x = 160
	hb.add_child(tit)
	lbl_turno = Tema.etichetta("Turno 1", 24, Color("f3ead6"), "grassetto")
	lbl_turno.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lbl_turno.custom_minimum_size.x = 110
	hb.add_child(lbl_turno)
	barra_fasi = HBoxContainer.new()
	barra_fasi.add_theme_constant_override("separation", 3)
	hb.add_child(barra_fasi)
	for i in 10:
		var c = Label.new()
		c.text = str(i + 1)
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		c.custom_minimum_size = Vector2(34, 34)
		c.add_theme_font_override("font", Tema.font("grassetto"))
		c.add_theme_font_size_override("font_size", 18)
		c.tooltip_text = Regole.FASI[i]
		c.mouse_filter = Control.MOUSE_FILTER_PASS
		barra_fasi.add_child(c)
	lbl_fase = Tema.etichetta("", 22, Tema.ORO, "grassetto")
	lbl_fase.custom_minimum_size.x = 260
	hb.add_child(lbl_fase)
	for b in [["Vista", _cambia_vista], ["Griglia", _cambia_griglia], ["Diario", _mostra_diario], ["Regole", _mostra_regole], ["Menu", _menu]]:
		var bt = Tema.bottone(b[0], b[1], 18, 84)
		hb.add_child(bt)
	# colonna sinistra: scheda dell'aereo e elenco
	sinistra = Tema.pannello_scuro(8)
	sinistra.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	sinistra.offset_top = 70
	sinistra.offset_right = 392
	sinistra.offset_bottom = -8
	sinistra.offset_left = 8
	add_child(sinistra)
	var sc = ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sinistra.add_child(sc)
	var vs = VBoxContainer.new()
	vs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(vs)
	var sw = HBoxContainer.new()
	sw.add_theme_constant_override("separation", 4)
	vs.add_child(sw)
	bt_scheda = Tema.bottone("Scheda", func(): _vista_aereo(false), 18)
	bt_miniatura = Tema.bottone("Miniatura", func(): _vista_aereo(true), 18)
	for b in [bt_scheda, bt_miniatura]:
		b.toggle_mode = true
		b.add_theme_stylebox_override("pressed", Tema.box(Tema.ORO, Tema.INCHIOSTRO, 2, 6, 8))
		b.add_theme_color_override("font_pressed_color", Tema.INCHIOSTRO)
		b.add_theme_stylebox_override("normal", Tema.box(Color("4f3d28"), Tema.NOTTE_BORDO, 2, 6, 8))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sw.add_child(b)
	scheda = SchedaAereo.new()
	scheda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vs.add_child(scheda)
	miniatura = VistaDanni.new()
	miniatura.visible = false
	vs.add_child(miniatura)
	bt_scheda.button_pressed = true
	vs.add_child(Tema.etichetta("Aerei in volo", 20, Tema.ORO, "grassetto"))
	lista_aerei = VBoxContainer.new()
	vs.add_child(lista_aerei)
	# colonna destra: azioni
	destra = Tema.pannello_scuro(8)
	destra.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	destra.offset_top = 70
	destra.offset_left = -600
	destra.offset_right = -8
	destra.offset_bottom = -8
	add_child(destra)
	pannello_azione = destra
	var va = VBoxContainer.new()
	destra.add_child(va)
	titolo_azione = Tema.etichetta("", 26, Tema.ORO, "titolo", 470)
	va.add_child(titolo_azione)
	var sca = ScrollContainer.new()
	sca.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sca.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	va.add_child(sca)
	corpo_azione = VBoxContainer.new()
	corpo_azione.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	corpo_azione.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sca.add_child(corpo_azione)
	bottoni_azione = HBoxContainer.new()
	bottoni_azione.alignment = BoxContainer.ALIGNMENT_END
	va.add_child(bottoni_azione)
	# banner degli annunci in basso al centro
	banner = Label.new()
	banner.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	banner.offset_top = -90
	banner.offset_bottom = -30
	banner.offset_left = -360
	banner.offset_right = 360
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner.add_theme_font_override("font", Tema.font("grassetto"))
	banner.add_theme_font_size_override("font_size", 24)
	banner.add_theme_color_override("font_color", Color.WHITE)
	banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	banner.add_theme_constant_override("outline_size", 8)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)
	# diario (nascosto)
	pannello_diario = Tema.pannello(Tema.CARTA, Tema.SEPPIA, 12)
	pannello_diario.set_anchors_preset(Control.PRESET_CENTER)
	pannello_diario.custom_minimum_size = Vector2(820, 620)
	pannello_diario.position = Vector2(-410, -310)
	pannello_diario.visible = false
	add_child(pannello_diario)
	var vd = VBoxContainer.new()
	pannello_diario.add_child(vd)
	vd.add_child(Tema.titolo("Diario di volo", 34))
	diario = RichTextLabel.new()
	diario.bbcode_enabled = true
	diario.scroll_following = true
	diario.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diario.add_theme_font_override("normal_font", Tema.font("documento"))
	diario.add_theme_font_size_override("normal_font_size", 19)
	vd.add_child(diario)
	vd.add_child(Tema.bottone("Chiudi", func(): pannello_diario.visible = false, 20))
	# velo e finestra modale
	velo = ColorRect.new()
	velo.color = Color(0, 0, 0, 0.55)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.visible = false
	add_child(velo)
	modale = CenterContainer.new()
	modale.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modale.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modale)
	destra.visible = false
	_aggiorna_fasi(0)

func _aggiorna_fasi(f: int) -> void:
	for i in barra_fasi.get_child_count():
		var c: Label = barra_fasi.get_child(i)
		var s = StyleBoxFlat.new()
		s.set_corner_radius_all(17)
		if i == f:
			s.bg_color = Tema.ROSSO_CHIARO
			c.add_theme_color_override("font_color", Color.WHITE)
		elif i < f:
			s.bg_color = Color("5b4a32")
			c.add_theme_color_override("font_color", Color("cdbd9c"))
		else:
			s.bg_color = Color("2f281f")
			c.add_theme_color_override("font_color", Color("a8987a"))
		c.add_theme_stylebox_override("normal", s)
	_fase_base = ""
	lbl_fase.text = Regole.FASI[f]
	lbl_turno.text = "Turno %d" % int(R.S["turno"]) if R else "Turno 1"
	if ospite:
		return
	R.S["fase"] = f
	_pubblica()

func annuncia(t: String, durata := 2.2) -> void:
	banner.text = t
	banner.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_interval(durata)
	tw.tween_property(banner, "modulate:a", 0.0, 0.6)

func _pausa(s: float) -> void:
	if in_replay:
		s *= 0.6
	elif veloce:
		s *= 0.35
	await get_tree().create_timer(s).timeout

func _aggiorna_diario() -> void:
	var t = ""
	var colori = {"fuoco": "8e2420", "abbattuto": "8e2420", "vittoria": "3f6b2f", "fuga": "2e5f96", "vite": "8e2420", "avviso": "6b5437"}
	for d in R.S["diario"]:
		var c: String = colori.get(d["tipo"], "2a2118")
		t += "[color=#%s]T%d  %s[/color]\n" % [c, int(d["t"]), d["testo"]]
	diario.text = t

# --------------------------------------------------------------------------- elenco aerei e scheda
func _aggiorna_lista() -> void:
	for c in lista_aerei.get_children():
		c.queue_free()
	for a in R.S["aerei"]:
		var b = Button.new()
		var stato = ""
		if not R.in_gioco(a):
			stato = " - " + {"abbattuto": "abbattuto", "fuggito": "rientrato", "atterrato": "atterrato", "catturato": "catturato"}.get(a["stato"], "")
		var chi = {"umano": "Tu", "ia": "Computer", "telefono": "Online"}.get(a["controllo"], "")
		if a["controllo"] == "umano" and a["giocatore"] != "":
			chi = a["giocatore"]
		b.text = "%s  (%s)  %s%s" % [a["pilota"], Dati.aerei[a["tipo"]]["nome"], chi, stato]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.custom_minimum_size = Vector2(360, 40)
		b.add_theme_font_size_override("font_size", 17)
		var col = Tema.colore_lato(a["lato"])
		b.add_theme_stylebox_override("normal", Tema.box(col.darkened(0.45 if R.in_gioco(a) else 0.75), col, 2, 5, 8))
		b.add_theme_stylebox_override("hover", Tema.box(col.darkened(0.2), Tema.ORO, 2, 5, 8))
		b.focus_mode = Control.FOCUS_NONE
		var id: int = a["id"]
		b.pressed.connect(func(): mostra_aereo(id); mondo.centra_su(mondo.posizione_aereo(id)))
		lista_aerei.add_child(b)

func mostra_aereo(id: int) -> void:
	aereo_mostrato = id
	var a = R.aereo(id)
	scheda.imposta(R, a, _segreto(a))
	if miniatura.visible:
		miniatura.imposta(a, _segreto(a))

func _vista_aereo(mini: bool) -> void:
	bt_scheda.button_pressed = not mini
	bt_miniatura.button_pressed = mini
	scheda.visible = not mini
	miniatura.visible = mini
	if mini and aereo_mostrato >= 0:
		var a = R.aereo(aereo_mostrato)
		miniatura.imposta(a, _segreto(a))

## I danni dei nemici restano segreti (regola della Segretezza), salvo opzione contraria
func _segreto(a: Dictionary) -> bool:
	if R.S["opzioni"].get("danni_visibili", false):
		return false
	if a["controllo"] == "umano":
		return false
	var umani = R.S["aerei"].filter(func(x): return x["controllo"] == "umano")
	if umani.is_empty():
		return false
	for u in umani:
		if u["lato"] == a["lato"]:
			return false
	return true

func _aereo_toccato(id: int) -> void:
	mostra_aereo(id)
	if _cb_tocco_aereo.is_valid():
		_cb_tocco_aereo.call(id)

var _cb_tocco_aereo = Callable()

func _cella_toccata(c: Vector2i) -> void:
	pass

# --------------------------------------------------------------------------- ciclo del turno
func ciclo() -> void:
	while not R.S["finita"]:
		await turno()
		if not is_inside_tree():
			return
	await fine_partita()

func turno() -> void:
	turno_corrente = {"inizio": JSON.parse_string(JSON.stringify(R.S)), "mov": [], "fuoco": [], "danni": []}
	turno_corrente["inizio"].erase("storia")
	turno_corrente["inizio"]["diario"] = []
	# 1. tallonamento
	_aggiorna_fasi(0)
	var tall = R.calcola_tallonamenti()
	mondo.pulisci_evid()
	if not tall.is_empty():
		var testi = []
		for k in tall:
			testi.append("%s tallona %s" % [R.aereo(k)["pilota"], R.aereo(tall[k])["pilota"]])
		annuncia("\n".join(testi), 3.0)
		await _pausa(1.4)
	if tutorial:
		await tutorial.fase("tallonamento")
	# 2. scelta della manovra
	_aggiorna_fasi(1)
	await _fase_scelta()
	# 3. carburante
	_aggiorna_fasi(2)
	R.fase_carburante()
	# 4. movimento
	_aggiorna_fasi(3)
	_pulisci_azione("")
	mondo.pulisci_segni()
	mondo.pulisci_evid()
	var evm = R.fase_movimento()
	anim_seq += 1
	ultimo_anim = {"seq": anim_seq, "mov": evm}
	turno_corrente["mov"] = evm
	for ev in evm:
		mondo.anima_manovra(R.aereo(ev["id"]), ev, 1.9 if not veloce else 1.0)
	await get_tree().process_frame
	await mondo.aspetta_animazioni()
	for ev in evm:
		var a = R.aereo(ev["id"])
		mondo.aggiorna(a)
		match ev["esito"]:
			"fuga": annuncia("%s esce dalla mappa e rientra alla base" % a["pilota"])
			"stallo": annuncia("%s va in stallo!" % a["pilota"])
			"vite": annuncia("%s entra in avvitamento!" % a["pilota"])
			"schianto":
				annuncia("%s si schianta al suolo!" % a["pilota"])
				mondo.precipita(a["id"])
			"atterraggio": annuncia("%s atterra" % a["pilota"])
	await mondo.aspetta_animazioni()
	_aggiorna_lista()
	mostra_aereo(aereo_mostrato)
	if tutorial:
		await tutorial.fase("movimento")
	# 5. combattimento
	_aggiorna_fasi(4)
	await _fase_fuoco()
	# 6. risoluzione dei danni
	_aggiorna_fasi(5)
	var evd = R.fase_danni()
	await _mostra_danni(evd)
	# 7-10
	_aggiorna_fasi(6)
	_messaggi(R.fase_recupero())
	_aggiorna_fasi(7)
	_messaggi(R.fase_incidenti())
	_aggiorna_fasi(8)
	var evi = R.fase_incendi()
	if not evi.is_empty():
		Suoni.suona("fuoco")
		await _mostra_danni(evi)
	_aggiorna_fasi(9)
	_messaggi(R.fase_spegnimento())
	for a in R.S["aerei"]:
		mondo.aggiorna(a)
		if a["stato"] == "abbattuto" and mondo.nodi[a["id"]]["stato"] != "abbattuto_visto":
			pass
	await mondo.aspetta_animazioni()
	R.fine_turno()
	storia.append(turno_corrente)

	_aggiorna_lista()
	mostra_aereo(aereo_mostrato)
	_aggiorna_diario()
	_salva()
	if tutorial:
		await tutorial.fase("fine_turno")
	await _pausa(0.6)

func _messaggi(ev: Array) -> void:
	var t = []
	for e in ev:
		var a = R.aereo(e["id"])
		t.append("%s: %s" % [a["pilota"], e["testo"]])
		mondo.aggiorna(a)
		if e.get("schianto", false):
			mondo.precipita(a["id"])
	if not t.is_empty():
		annuncia("\n".join(t), 3.0)

# --------------------------------------------------------------------------- fase 2: scelta della manovra
func _fase_scelta() -> void:
	var ordine = R.ordine_scelta()
	var scelte = {}
	var info = {}   # informazioni rivelate a chi tallona: id_tallonato -> {dir, quota}
	var umani_locali = ordine.filter(func(id): return R.aereo(id)["controllo"] == "umano")
	var giocatori = {}
	for id in umani_locali:
		giocatori[R.aereo(id)["giocatore"] if R.aereo(id)["giocatore"] != "" else R.aereo(id)["lato"]] = true
	var nascondi = giocatori.size() > 1
	dal_telefono.clear()
	richieste_tel.clear()
	var in_attesa = ordine.duplicate()
	while not in_attesa.is_empty():
		var progresso = false
		for id in in_attesa.duplicate():
			var a = R.aereo(id)
			var t: int = a.get("tallona", -1)
			if t >= 0 and t in in_attesa:
				continue
			var mia = {}
			if t >= 0 and info.has(str(t)):
				mia[str(t)] = info[str(t)]
			var m = {}
			match a["controllo"]:
				"ia":
					m = ia[a["lato"]].scegli_manovra(a, mia)
				"umano":
					if nascondi:
						await _schermo_passa(a)
					m = await _scelta_umana(a, mia)
				"telefono":
					if dal_telefono.has(id):
						m = dal_telefono[id]
					else:
						if not richieste_tel.has(id):
							richieste_tel[id] = {"tipo": "manovra", "opzioni": R.manovre_possibili(a), "info": _testo_info(mia)}
							_pubblica()
						continue
			scelte[id] = m
			in_attesa.erase(id)
			progresso = true
			if not a.get("tallonato_da", []).is_empty():
				info[str(id)] = {"dir": Dati.codice(m["codice"])["dir"], "quota": int(m["quota"])}
		if not progresso:
			_attesa_telefoni("la manovra di " + ", ".join(in_attesa.map(func(i): return R.aereo(i)["pilota"])))
			await get_tree().create_timer(0.3).timeout
	richieste_tel.clear()
	dal_telefono.clear()
	_fine_attesa()
	R.applica_scelte(scelte)
	_pubblica()

func _testo_info(mia: Dictionary) -> String:
	var t = []
	for k in mia:
		var b = R.aereo(int(k))
		var d: String = {"A": "AVANTI", "S": "a SINISTRA", "D": "a DESTRA"}[mia[k]["dir"]]
		var q: String = {1: "e SALE di quota", -1: "e SCENDE di quota", 0: "e resta alla stessa quota"}[int(mia[k]["quota"])]
		t.append("Stai tallonando %s: farà una manovra %s %s." % [b["pilota"], d, q])
	return " ".join(t)

func _schermo_passa(a: Dictionary) -> void:
	velo.visible = true
	velo.color = Color(0.05, 0.04, 0.03, 0.97)
	var p = Tema.pannello(Tema.CARTA, Tema.SEPPIA, 24)
	p.custom_minimum_size = Vector2(640, 0)
	var v = VBoxContainer.new()
	p.add_child(v)
	v.add_child(Tema.titolo("Tocca a %s" % a["pilota"], 40))
	v.add_child(Tema.etichetta("%s, %s. Gli altri giocatori non guardino lo schermo: la manovra è segreta." % [Dati.aerei[a["tipo"]]["nome"], Dati.NAZIONI[a["nazione"]]["nome"]], 22, Tema.INCHIOSTRO, "testo", 580))
	var b = Tema.bottone("Sono pronto", func(): avanti.emit(), 26)
	v.add_child(b)
	modale.add_child(p)
	await avanti
	p.queue_free()
	velo.visible = false
	velo.color = Color(0, 0, 0, 0.55)

## Mentre si aspettano i giocatori da fuori basta una scritta nella barra in alto, niente pannello
var _fase_base = ""
func _attesa_telefoni(cosa: String) -> void:
	if destra.visible:
		_pulisci_azione("")
	if _fase_base == "":
		_fase_base = lbl_fase.text
	lbl_fase.text = "%s  -  aspetto %s" % [_fase_base, cosa]

func _fine_attesa() -> void:
	if _fase_base != "":
		lbl_fase.text = _fase_base
		_fase_base = ""

func _pulisci_azione(t: String) -> void:
	if _fase_base != "":
		lbl_fase.text = _fase_base
		_fase_base = ""
	titolo_azione.text = t
	destra.visible = t != "" and not in_replay
	for c in corpo_azione.get_children():
		c.queue_free()
	for c in bottoni_azione.get_children():
		c.queue_free()
	_cb_tocco_aereo = Callable()

func _scelta_umana(a: Dictionary, mia: Dictionary, info_testo := "") -> Dictionary:
	mostra_aereo(a["id"])
	mondo.centra_su(mondo.posizione_aereo(a["id"]), 14.0)
	var possibili = R.manovre_possibili(a)
	_pulisci_azione("Manovra di %s" % a["pilota"])
	var testo_info = _testo_info(mia) if info_testo == "" else info_testo
	if testo_info != "":
		corpo_azione.add_child(_nota(testo_info, Tema.ORO))
	var tallonatori: Array = a.get("tallonato_da", [])
	if not tallonatori.is_empty():
		var nomi = tallonatori.map(func(i): return R.aereo(i)["pilota"])
		corpo_azione.add_child(_nota("Sei tallonato da %s: la direzione della tua manovra gli verrà rivelata." % ", ".join(nomi), Color("f0a090")))
	if possibili.size() == 1 and possibili[0].get("forzata", "") != "":
		var f: String = possibili[0]["forzata"]
		corpo_azione.add_child(_nota("Manovra obbligata: %s." % ("avvitamento (0A2)" if f == "vite" else "stallo (1A1)"), Color("f0a090")))
	var vincoli = _vincoli(a)
	if vincoli != "":
		corpo_azione.add_child(_nota(vincoli, Color("d8c8a8")))
	var foglio = Tema.pannello(Color("efe5cc"), Tema.SEPPIA, 6)
	foglio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo_azione.add_child(foglio)
	var sm = SchedaMovimento.new()
	foglio.add_child(sm)
	sm.imposta(a, possibili)
	# quota
	var hq = HBoxContainer.new()
	corpo_azione.add_child(hq)
	var dettaglio = Tema.etichetta("Tocca una manovra sulla scheda.", 20, Color("f3ead6"), "testo", 470)
	var bq = {}
	var stato = {"codice": "", "quota": 0}
	var conferma = Tema.bottone("Conferma la manovra", func(): pass, 24)
	conferma.disabled = true
	var aggiorna = func():
		var c: String = stato["codice"]
		if c == "":
			return
		var ok = {}
		for m in possibili:
			if m["codice"] == c:
				ok[int(m["quota"])] = m
		for k in bq:
			bq[k].disabled = not ok.has(k)
		if not ok.has(int(stato["quota"])):
			stato["quota"] = ok.keys()[0] if not ok.is_empty() else 0
		for k in bq:
			bq[k].button_pressed = k == int(stato["quota"])
		var m: Dictionary = ok.get(int(stato["quota"]), {})
		var g = Dati.geometria(c)
		var testo = "%s - %s. Velocità %d, carburante %d." % [c, Dati.nome_manovra(c), int(g["vel"]), int(m.get("carb", 0))]
		if g["acrobatica"]:
			testo += " Manovra acrobatica."
		if g["non_ripetibile"]:
			testo += " Non ripetibile due volte di seguito."
		if m.get("fuga", false):
			testo += " Uscirai dalla mappa: rientro alla base!"
		if int(stato["quota"]) == -1 and int(a["quota"]) == 0:
			testo += " Atterraggio."
		dettaglio.text = testo
		mondo.anteprima(a, c, int(stato["quota"]))
		conferma.disabled = m.is_empty()
	for k in [1, 0, -1]:
		var nome: String = {1: "Cabrata (sale)", 0: "Stessa quota", -1: "Picchiata (scende)"}[k]
		var b = Tema.bottone(nome, func(): stato["quota"] = k; aggiorna.call(), 19)
		b.toggle_mode = true
		b.disabled = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bq[k] = b
		hq.add_child(b)
	corpo_azione.add_child(dettaglio)
	sm.scelta.connect(func(c): stato["codice"] = c; aggiorna.call())
	if possibili.size() == 1:
		stato["codice"] = possibili[0]["codice"]
		sm.seleziona(stato["codice"])
		aggiorna.call()
	if tutorial:
		tutorial.scelta_aperta(sm, possibili)
	conferma.pressed.connect(func():
		for m in possibili:
			if m["codice"] == stato["codice"] and int(m["quota"]) == int(stato["quota"]):
				scelta_fatta.emit(m)
				return)
	bottoni_azione.add_child(conferma)
	var m: Dictionary = await scelta_fatta
	mondo.pulisci_segni()
	mondo.pulisci_evid()
	_pulisci_azione("")
	return m

func _nota(t: String, col: Color) -> Label:
	return Tema.etichetta(t, 20, col, "testo", 470)

func _vincoli(a: Dictionary) -> String:
	var v = []
	if a["ultima"] != "":
		v.append("Ultima manovra %s (velocità %d): ora velocità da %d a %d." % [a["ultima"], int(Dati.codice(a["ultima"])["vel"]), maxi(1, int(Dati.codice(a["ultima"])["vel"]) - 1), int(Dati.codice(a["ultima"])["vel"]) + 1])
	v.append("Carburante: %d." % int(a["carb"]))
	if a["novellino"]:
		v.append("Novellino: niente acrobazie.")
	if int(a["obbligo"]) == 1:
		v.append("Hai sparato a un bersaglio più in alto: devi cabrare.")
	elif int(a["obbligo"]) == -1:
		v.append("Hai sparato a un bersaglio più in basso: devi picchiare.")
	if a["stato"] == "planata":
		v.append("Motore fermo: planata, solo manovre 2 o 9 e in discesa.")
	return " ".join(v)

# --------------------------------------------------------------------------- fase 5: combattimento
func _fase_fuoco() -> void:
	var attacchi = []
	richieste_tel.clear()
	dal_telefono.clear()
	for a in R.attivi():
		var bersagli = []
		for b in R.nemici(a):
			if not R.puo_sparare(a, b).is_empty():
				bersagli.append(b)
		if bersagli.is_empty():
			continue
		match a["controllo"]:
			"ia":
				attacchi += ia[a["lato"]].scegli_attacchi(a)
			"umano":
				attacchi += await _fuoco_umano(a)
			"telefono":
				richieste_tel[a["id"]] = {"tipo": "fuoco", "opzioni": _opzioni_fuoco(a)}
	if not richieste_tel.is_empty():
		_pubblica()
		while true:
			var mancano = richieste_tel.keys().filter(func(id): return not dal_telefono.has(id))
			if mancano.is_empty():
				break
			_attesa_telefoni("gli spari di " + ", ".join(mancano.map(func(i): return R.aereo(i)["pilota"])))
			await get_tree().create_timer(0.4).timeout
		_fine_attesa()
		for id in richieste_tel:
			if dal_telefono[id] is Array:
				attacchi += dal_telefono[id]
		richieste_tel.clear()
		dal_telefono.clear()
	if attacchi.is_empty():
		R.fase_combattimento([])
		return
	var eventi = R.fase_combattimento(attacchi)
	turno_corrente["fuoco"] = eventi.map(func(e): return {"da": e["da"], "a": e["a"], "raffica": e["raffica"], "arma": e["arma"], "colpito": int(e["blu"]) + int(e["rosse"]) > 0})
	anim_seq += 1
	ultimo_anim = {"seq": anim_seq, "fuoco": turno_corrente["fuoco"]}
	for ev in eventi:
		await _mostra_attacco(ev)
	_aggiorna_diario()

func _opzioni_fuoco(a: Dictionary) -> Array:
	var out = []
	for b in R.nemici(a):
		for x in R.puo_sparare(a, b):
			var val = {}
			for r in R.raffiche_possibili(a, x["arma"]):
				val[r] = int(R.valore_fuoco(a, b, x["arma"], r)["valore"])
			out.append({"a": b["id"], "nome": b["pilota"], "tipo": Dati.aerei[b["tipo"]]["nome"], "arma": x["arma"], "distanza": x["distanza"], "valori": val})
	return out

func _fuoco_umano(a: Dictionary) -> Array:
	mostra_aereo(a["id"])
	var opz = _opzioni_fuoco(a)
	_pulisci_azione("Fuoco di %s" % a["pilota"])
	corpo_azione.add_child(_nota("Scegli il bersaglio e la lunghezza della raffica. Le raffiche lunghe colpiscono di più ma possono inceppare le mitragliatrici (5 o 6). Media o lunga contro un aereo più in alto o più in basso obbliga a cabrare o picchiare il turno dopo.", Color("d8c8a8")))
	var scelte = {}   # arma -> {a, raffica}
	var bottoni = []
	for o in opz:
		var riga = Tema.pannello(Color("efe5cc"), Tema.SEPPIA, 8)
		var v = VBoxContainer.new()
		riga.add_child(v)
		var b = R.aereo(int(o["a"]))
		var testo = "%s  (%s)  -  %s, distanza %d, quota %s" % [o["nome"], o["tipo"], "mitragliatrici del pilota" if o["arma"] == "pilota" else "osservatore", int(o["distanza"]), Dati.QUOTE[int(b["quota"])]]
		v.add_child(Tema.etichetta(testo, 19, Tema.INCHIOSTRO, "grassetto", 460))
		var h = HBoxContainer.new()
		v.add_child(h)
		for r in ["corta", "media", "lunga"]:
			if not o["valori"].has(r):
				continue
			var val: int = o["valori"][r]
			var bt = Tema.bottone("%s  %d" % [r.capitalize(), val], func(): pass, 19)
			bt.toggle_mode = true
			bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bt.tooltip_text = "Valore di fuoco %d" % val
			var arma: String = o["arma"]
			var bid: int = o["a"]
			bt.pressed.connect(func():
				if scelte.get(arma, {}).get("a", -1) == bid and scelte[arma]["raffica"] == r:
					scelte.erase(arma)
				else:
					scelte[arma] = {"a": bid, "raffica": r}
				for x in bottoni:
					x[0].button_pressed = scelte.get(x[1], {}).get("a", -1) == x[2] and scelte[x[1]]["raffica"] == x[3]
				_mostra_mod(a, scelte))
			bottoni.append([bt, arma, bid, r])
			h.add_child(bt)
		corpo_azione.add_child(riga)
	var mods = VBoxContainer.new()
	mods.name = "Mod"
	corpo_azione.add_child(mods)
	# linea di tiro sulla mappa
	var lin = Hex.linea(R.pos(a), a["prua"], 3)
	mondo.evidenzia(lin, Color(1, 0.3, 0.2, 0.8), true)
	_cb_tocco_aereo = func(id):
		for x in bottoni:
			if x[2] == id and x[3] == "media":
				x[0].emit_signal("pressed")
				return
	if tutorial:
		tutorial.fuoco_aperto(bottoni)
	bottoni_azione.add_child(Tema.bottone("Non sparare", func(): fuoco_fatto.emit([]), 20))
	bottoni_azione.add_child(Tema.bottone("Fuoco!", func():
		var l = []
		for arma in scelte:
			l.append({"da": a["id"], "a": scelte[arma]["a"], "arma": arma, "raffica": scelte[arma]["raffica"]})
		fuoco_fatto.emit(l), 24))
	var l: Array = await fuoco_fatto
	mondo.pulisci_evid()
	_pulisci_azione("")
	return l

func _mostra_mod(a: Dictionary, scelte: Dictionary) -> void:
	var box: Node = corpo_azione.get_node_or_null("Mod")
	if box == null:
		return
	for c in box.get_children():
		c.queue_free()
	for arma in scelte:
		var b = R.aereo(int(scelte[arma]["a"]))
		var vf = R.valore_fuoco(a, b, arma, scelte[arma]["raffica"])
		var t = "Valore di fuoco contro %s: %d  (" % [b["pilota"], int(vf["valore"])]
		t += ", ".join(vf["mod"].map(func(m): return "%s %+d" % [m[0], int(m[1])] if m[0].begins_with("Distanza") == false else "%s: %d" % [m[0], int(m[1])]))
		t += ")"
		box.add_child(_nota(t, Tema.ORO))

## Animazione di un attacco: raffica in 3D, dado, incrocio sulla tabella, pedine-danno estratte
func _mostra_attacco(ev: Dictionary) -> void:
	var a = R.aereo(int(ev["da"]))
	var b = R.aereo(int(ev["a"]))
	var colpito: bool = int(ev["blu"]) + int(ev["rosse"]) > 0
	mondo.centra_su((mondo.posizione_aereo(a["id"]) + mondo.posizione_aereo(b["id"])) / 2.0, 11.0)
	var fin = FinestraCombattimento.new()
	fin.R = R
	fin.ev = ev
	fin.segreto = _segreto(b)
	fin.veloce = veloce or in_replay
	add_child(fin)
	move_child(fin, banner.get_index())
	await mondo.spara(a["id"], b["id"], ev["arma"], ev["raffica"], colpito)
	await fin.mostra()
	fin.queue_free()

# --------------------------------------------------------------------------- fase 6: danni
func _mostra_danni(ev: Array) -> void:
	var visti = {}
	for e in ev:
		var a = R.aereo(int(e["id"]))
		if e.has("pedina") and e["testo"].begins_with("Incendio"):
			annuncia("%s brucia: %s" % [a["pilota"], "" if _segreto(a) else e["testo"].substr(10)])
			await _pausa(0.8)
	for a in R.S["aerei"]:
		var n: Dictionary = mondo.nodi.get(a["id"], {})
		if n.is_empty():
			continue
		if a["stato"] == "abbattuto" and n["stato"] != "abbattuto":
			var spec = ""
			for p in a["danni_visti"]:
				spec = p.get("spec", spec)
			if spec == "esplosione" or a["fuoco"]:
				await mondo.esplosione(a["id"])
			else:
				await mondo.precipita(a["id"])
			n["stato"] = "abbattuto"
			annuncia("%s è abbattuto!" % R.nome(a), 3.0)
			turno_corrente["danni"].append(a["id"])
			anim_seq += 1
			ultimo_anim = {"seq": anim_seq, "danni": [a["id"]]}
			await _pausa(1.0)
		else:
			mondo.aggiorna(a)
	_aggiorna_lista()
	mostra_aereo(aereo_mostrato)

# --------------------------------------------------------------------------- fine, replay, salvataggi
func fine_partita() -> void:
	_aggiorna_diario()
	rete_cancella_salvataggio()
	if tutorial:
		await tutorial.fase("fine")
	var v: String = R.S["vincitore"]
	var umani = R.S["aerei"].filter(func(a): return a["controllo"] != "ia")
	var titolo = "Fine del combattimento"
	if v == "pari":
		titolo = "Nessun vincitore"
	elif not umani.is_empty():
		var mio: String = umani[0]["lato"]
		titolo = "Vittoria!" if v == mio else "Sconfitta"
	else:
		titolo = "Vincono i Tedeschi" if v == "G" else "Vincono gli Alleati"
	var p = Tema.pannello(Tema.CARTA, Tema.SEPPIA, 24)
	p.custom_minimum_size = Vector2(760, 0)
	var vb = VBoxContainer.new()
	p.add_child(vb)
	vb.add_child(Tema.titolo(titolo, 52, Tema.ROSSO))
	for a in R.S["aerei"]:
		var st = {"volo": "in volo", "planata": "in planata", "vite": "in avvitamento", "abbattuto": "abbattuto", "fuggito": "rientrato alla base", "atterrato": "atterrato", "catturato": "catturato"}[a["stato"]]
		var t = "%s (%s, %s): %s" % [a["pilota"], Dati.aerei[a["tipo"]]["nome"], Dati.NAZIONI[a["nazione"]]["nome"], st]
		if int(a["abbattimenti"]) > 0:
			t += " - %d abbattiment%s" % [int(a["abbattimenti"]), "o" if int(a["abbattimenti"]) == 1 else "i"]
		vb.add_child(Tema.etichetta(t, 21, Tema.INCHIOSTRO, "testo", 700))
	var hb = HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	hb.add_child(Tema.bottone("Rivedi il combattimento", func(): p.visible = false; await replay(); p.visible = true, 22))
	hb.add_child(Tema.bottone("Diario", _mostra_diario, 22))
	hb.add_child(Tema.bottone(("Torna alla campagna" if not campagna.is_empty() else "Torna al menu"), func(): uscita.emit(), 22))
	velo.visible = true
	modale.add_child(p)

## Anima un turno già giocato a partire dallo stato R0 (replay e ospite online)
func _anima_turno(R0: Regole, t: Dictionary, durata := 1.2) -> void:
	for ev in t.get("mov", []):
		var a = R0.aereo(int(ev["id"]))
		if R0.in_gioco(a):
			mondo.anima_manovra(a, ev, durata)
	await get_tree().process_frame
	await mondo.aspetta_animazioni()
	for ev in t.get("mov", []):
		var a = R0.aereo(int(ev["id"]))
		var f: Dictionary = ev["percorso"][-1]
		a["q"] = int(f["q"])
		a["r"] = int(f["r"])
		a["prua"] = int(f["prua"])
		a["quota"] = int(ev["quota_a"])
		if ev["esito"] == "fuga":
			a["stato"] = "fuggito"
		mondo.aggiorna(a)
	for f in t.get("fuoco", []):
		await mondo.spara(int(f["da"]), int(f["a"]), f["arma"], f["raffica"], f["colpito"])
	for id in t.get("danni", []):
		await mondo.esplosione(int(id))

## Replay continuo: i turni si susseguono senza pause, gli spari e le esplosioni partono durante il volo
func replay() -> void:
	if storia.is_empty():
		return
	velo.visible = false
	in_replay = true
	var vero = R
	sinistra.visible = false
	destra.visible = false
	var primo = Regole.new(JSON.parse_string(JSON.stringify(storia[0]["inizio"])))
	R = primo
	mondo.R = primo
	mondo.pulisci_effetti()
	mondo.crea_aerei()
	_centra_inizio()
	annuncia("Replay del combattimento", 2.0)
	await get_tree().create_timer(0.6).timeout
	const DUR = 1.4
	for t in storia:
		var finto = Regole.new(JSON.parse_string(JSON.stringify(t["inizio"])))
		R = finto
		mondo.R = finto
		lbl_turno.text = "Replay - turno %d" % int(finto.S["turno"])
		# la telecamera segue il gruppo con calma
		var c = Vector3.ZERO
		var n = 0
		for a in finto.attivi():
			c += mondo.mondo_da_cella(finto.pos(a))
			n += 1
		if n > 0:
			mondo.centra_su(c / n)
		for ev in t.get("mov", []):
			var a = finto.aereo(int(ev["id"]))
			if finto.in_gioco(a):
				mondo.anima_manovra(a, ev, DUR, true)
		await get_tree().create_timer(DUR * 0.55).timeout
		for f in t.get("fuoco", []):
			mondo.spara(int(f["da"]), int(f["a"]), f["arma"], f["raffica"], f["colpito"])
		await mondo.aspetta_animazioni()
		for ev in t.get("mov", []):
			var a = finto.aereo(int(ev["id"]))
			var f: Dictionary = ev["percorso"][-1]
			a["q"] = int(f["q"])
			a["r"] = int(f["r"])
			a["prua"] = int(f["prua"])
			a["quota"] = int(ev["quota_a"])
			if ev["esito"] == "fuga":
				a["stato"] = "fuggito"
				mondo.aggiorna(a)
		for id in t.get("danni", []):
			var nd: Dictionary = mondo.nodi.get(int(id), {})
			if not nd.is_empty():
				nd["stato"] = "abbattuto"
				mondo.esplosione(int(id))
	await get_tree().create_timer(2.5).timeout
	R = vero
	mondo.R = vero
	mondo.pulisci_effetti()
	mondo.crea_aerei()
	in_replay = false
	sinistra.visible = true
	lbl_turno.text = "Turno %d" % int(R.S["turno"])
	velo.visible = true

func _salva() -> void:
	if rete == null or not campagna.is_empty() and campagna.get("no_salvataggio", false):
		return
	var dati = {"S": R.S, "storia": storia.slice(maxi(0, storia.size() - 40)), "livelli": livelli, "campagna": campagna}
	rete.salva(nome_salvataggio, JSON.stringify(dati))

func rete_cancella_salvataggio() -> void:
	if rete:
		rete.salva(nome_salvataggio, "")

# --------------------------------------------------------------------------- pulsanti
func _cambia_vista() -> void:
	if mondo.pitch_dest > 80:
		mondo.vista_3d()
	else:
		mondo.vista_alto()

var _griglia = true
func _cambia_griglia() -> void:
	_griglia = not _griglia
	mondo.griglia_visibile(_griglia)

func _mostra_diario() -> void:
	_aggiorna_diario()
	pannello_diario.visible = not pannello_diario.visible
	if pannello_diario.visible:
		move_child(pannello_diario, get_child_count() - 1)

func _mostra_regole() -> void:
	var r = Regolamento.new()
	add_child(r)

func _menu() -> void:
	var p = Tema.pannello(Tema.CARTA, Tema.SEPPIA, 20)
	var v = VBoxContainer.new()
	p.add_child(v)
	v.add_child(Tema.titolo("Pausa", 40))
	v.add_child(Tema.etichetta("La partita è salvata a ogni turno: puoi riprenderla dal menu.", 20, Tema.INCHIOSTRO, "testo", 480))
	var cv = CheckBox.new()
	cv.text = "Animazioni veloci"
	cv.button_pressed = veloce
	cv.toggled.connect(func(x): veloce = x)
	v.add_child(cv)
	var cm = CheckBox.new()
	cm.text = "Rumore del motore in sottofondo"
	cm.button_pressed = Suoni.motore_attivo
	cm.toggled.connect(func(x): Suoni.imposta_motore(x))
	v.add_child(cm)
	var cs = CheckBox.new()
	cs.text = "Effetti sonori (spari, esplosioni, dado)"
	cs.button_pressed = not Suoni.muto
	cs.toggled.connect(func(x): Suoni.imposta_effetti(x))
	v.add_child(cs)
	var cd = CheckBox.new()
	cd.text = "Mostra i danni dei nemici (niente segretezza)"
	cd.button_pressed = R.S["opzioni"].get("danni_visibili", false)
	cd.toggled.connect(func(x): R.S["opzioni"]["danni_visibili"] = x; mostra_aereo(aereo_mostrato))
	v.add_child(cd)
	var h = HBoxContainer.new()
	v.add_child(h)
	h.add_child(Tema.bottone("Continua", func(): p.queue_free(); velo.visible = false, 22))
	h.add_child(Tema.bottone("Esci al menu", func(): p.queue_free(); velo.visible = false; uscita.emit(), 22))
	velo.visible = true
	modale.add_child(p)

func _unhandled_input(ev: InputEvent) -> void:
	if mondo and mondo.gestisci_input(ev):
		get_viewport().set_input_as_handled()

# --------------------------------------------------------------------------- rete e telefoni
func _pubblica() -> void:
	if rete == null or rete.codice == "":
		return
	var aerei = []
	for a in R.S["aerei"]:
		aerei.append({"id": a["id"], "pilota": a["pilota"], "tipo": a["tipo"], "nome": Dati.aerei[a["tipo"]]["nome"], "lato": a["lato"], "nazione": a["nazione"],
			"q": a["q"], "r": a["r"], "prua": a["prua"], "quota": a["quota"], "stato": a["stato"], "fuoco": a["fuoco"], "fumo": a["fumo"],
			"controllo": a["controllo"], "uid": a["uid"], "carb": a["carb"], "ali": a["ali"], "fus": a["fus"], "coda": a["coda"], "motore": a["motore"],
			"ultima": a["ultima"], "manovre": Dati.aerei[a["tipo"]]["manovre"],
			"tot": {"ali": Dati.aerei[a["tipo"]]["ali"], "fus": Dati.aerei[a["tipo"]]["fusoliera"], "coda": Dati.aerei[a["tipo"]]["coda"], "motore": Dati.aerei[a["tipo"]]["motore"]}, "abbattimenti": a["abbattimenti"]})
	var rich = {}
	for id in richieste_tel:
		if not dal_telefono.has(id):
			rich[str(id)] = richieste_tel[id]
	if ospite:
		return
	var S2 = R.S.duplicate()
	S2["diario"] = R.S["diario"].slice(maxi(0, R.S["diario"].size() - 40))
	rete.stato({"turno": R.S["turno"], "fase": R.S["fase"], "aerei": aerei, "richieste": rich, "finita": R.S["finita"], "S": S2, "anim": ultimo_anim,
		"diario": R.S["diario"].slice(maxi(0, R.S["diario"].size() - 8)).map(func(d): return d["testo"])})

func _evento_rete(e: Dictionary) -> void:
	if e.get("e") != "azione":
		return
	var p = e.get("p")
	if p is String:
		p = JSON.parse_string(p)
	if not (p is Dictionary):
		return
	var id = int(p.get("id", -1))
	if id < 0 or id >= R.S["aerei"].size():
		return
	var a = R.aereo(id)
	if a["controllo"] != "telefono" or (a["uid"] != "" and a["uid"] != e.get("uid", "")):
		return
	if not richieste_tel.has(id):
		return
	if e.get("k") == "manovra":
		for m in R.manovre_possibili(a):
			if m["codice"] == p.get("codice") and int(m["quota"]) == int(p.get("quota", 0)):
				dal_telefono[id] = m
				_pubblica()
				return
	elif e.get("k") == "fuoco":
		var l = []
		var valide = _opzioni_fuoco(a)
		for x in p.get("lista", []):
			for o in valide:
				if int(o["a"]) == int(x.get("a", -1)) and o["arma"] == x.get("arma") and o["valori"].has(x.get("raffica", "")):
					l.append({"da": id, "a": int(o["a"]), "arma": o["arma"], "raffica": x["raffica"]})
		dal_telefono[id] = l
		_pubblica()
