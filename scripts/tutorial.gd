class_name Tutorial
extends Control
## Tutorial a turni guidati: un istruttore spiega mappa, schede, manovre, quota, tallonamento,
## combattimento, pedine-danno, inceppamenti, avvitamenti e fine partita mentre si gioca un duello vero.
## Le spiegazioni arrivano quando la situazione si presenta per la prima volta; l'istruttore suggerisce
## la manovra migliore evidenziandola sulla scheda (ma si può scegliere liberamente).

signal ok
var gioco: Gioco
var pannello: PanelContainer
var testo: RichTextLabel
var bottone: Button
var visti = {}
var turno_guidato = 0
var attesa = false

func prepara() -> Regole:
	var S = Regole.nuova({"seme": 1917, "togli_pilota_ucciso": true})
	var R = Regole.new(S)
	S["scenario"] = "tutorial"
	R.aggiungi("albatros_d3", "germania", 3, 3, 1, 2, {"nome": "Leutnant Fischer", "novellino": true}, "ia")
	R.aggiungi("spad7", "francia", -1, 10, 5, 2, {"nome": "Sergent Dupont"}, "umano")
	R.avvia()
	return R

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pannello = Tema.pannello(Color("f3ead6"), Tema.ROSSO, 14)
	pannello.set_anchors_preset(Control.PRESET_CENTER_TOP)
	pannello.offset_top = 76
	pannello.offset_left = -430
	pannello.offset_right = 430
	pannello.custom_minimum_size = Vector2(860, 0)
	add_child(pannello)
	var v = VBoxContainer.new()
	pannello.add_child(v)
	var h = HBoxContainer.new()
	v.add_child(h)
	h.add_child(Tema.titolo("L'istruttore", 30, Tema.ROSSO))
	var salta = Tema.bottone("Salta il tutorial", func(): pannello.visible = false; visti["*"] = true; ok.emit(), 16)
	h.add_child(salta)
	testo = RichTextLabel.new()
	testo.bbcode_enabled = true
	testo.fit_content = true
	testo.custom_minimum_size = Vector2(820, 0)
	testo.add_theme_font_size_override("normal_font_size", 21)
	testo.add_theme_font_size_override("bold_font_size", 21)
	v.add_child(testo)
	bottone = Tema.bottone("Avanti", func(): ok.emit(), 22)
	bottone.size_flags_horizontal = Control.SIZE_SHRINK_END
	v.add_child(bottone)
	pannello.visible = false

func dici(t: String, aspetta := true) -> void:
	if visti.has("*"):
		return
	pannello.visible = true
	testo.text = t
	bottone.visible = aspetta
	get_parent().move_child(self, get_parent().get_child_count() - 1)
	if aspetta:
		await ok
		pannello.visible = false

func nota(t: String) -> void:
	if visti.has("*"):
		return
	pannello.visible = true
	testo.text = t
	bottone.visible = true
	bottone.text = "Ho capito"
	get_parent().move_child(self, get_parent().get_child_count() - 1)
	if not ok.is_connected(_chiudi_nota):
		ok.connect(_chiudi_nota, CONNECT_ONE_SHOT)

func _chiudi_nota() -> void:
	pannello.visible = false
	bottone.text = "Avanti"

func una_volta(k: String) -> bool:
	if visti.has(k) or visti.has("*"):
		return false
	visti[k] = true
	return true

func _io() -> Dictionary:
	for a in gioco.R.S["aerei"]:
		if a["controllo"] == "umano":
			return a
	return {}

func _lui() -> Dictionary:
	for a in gioco.R.S["aerei"]:
		if a["controllo"] != "umano":
			return a
	return {}

## Chiamato dal gioco nei momenti salienti del turno
func fase(nome: String) -> void:
	var R = gioco.R
	var io = _io()
	var lui = _lui()
	match nome:
		"tallonamento":
			if int(R.S["turno"]) == 1 and una_volta("intro"):
				gioco.mondo.vista_3d()
				await dici("Benvenuto in squadriglia, [b]Sergent Dupont[/b]! Sei il pilota dello [b]Spad VII[/b] francese, con l'anello [color=#2e6aa8]blu[/color], in basso. Lassù, con l'anello [color=#b8322a]rosso[/color], c'è un [b]Albatros D.III[/b] tedesco pilotato da un novellino. Oggi impari a combattere.\n\nPuoi muovere la vista: trascina con un dito (o con il tasto sinistro) per spostarti, pizzica con due dita (o usa la rotella) per avvicinarti, ruota con due dita (o con il tasto destro). Il pulsante [b]Vista[/b] in alto passa alla vista dall'alto.")
				await dici("La mappa è la foto della mappa originale con la griglia di [b]esagoni[/b]. Ogni aereo sta al centro di un esagono, con la prua verso un lato: l'anello colorato a terra e la freccia indicano la direzione. Il filo verticale e la sigla sopra l'aereo indicano la [b]quota[/b]: BB Molto Bassa, B Bassa, M Media, A Alta, MA Molto Alta. Si spara e si tallona solo alla stessa quota o a quella vicina.")
				await dici("A sinistra c'è la tua [b]Scheda-Aereo[/b]: le caselle di ali, fusoliera, coda, motore e carburante. I danni anneriscono le caselle: se finiscono quelle di ali, coda o fusoliera l'aereo precipita; senza motore o carburante si plana. In alto vedi le [b]10 fasi[/b] del turno, con quella in corso illuminata.")
				await dici("Un turno comincia con il [b]tallonamento[/b]: chi sta in coda a un nemico, cioè lo ha nel proprio arco frontale (entro 3 esagoni) e si trova nel suo arco posteriore, lo [i]tallona[/i]. Chi tallona scopre in anticipo in che direzione il nemico girerà. Ora siete troppo lontani: avanti con la scelta della manovra.")
			elif not lui.is_empty() and int(io.get("tallona", -1)) == int(lui["id"]) and una_volta("tallona"):
				await dici("[b]Ottimo: stai tallonando l'Albatros![/b] Sei nel suo arco posteriore e lo hai davanti. Quando sceglierai la manovra saprai se lui andrà avanti, a sinistra o a destra, e se sale o scende: usalo per restargli in coda. In più, sparargli ti dà il modificatore «bersaglio tallonato».")
			elif not io.is_empty() and int(lui.get("tallona", -1)) == int(io["id"]) and una_volta("tallonato"):
				await dici("[b]Attenzione: l'Albatros ti sta tallonando![/b] Ti è in coda e conoscerà la direzione della tua manovra. Per scrollartelo di dosso servono virate strette, cambi di quota o un'acrobazia, come l'Immelmann (29), che ti gira su te stesso.")
		"movimento":
			if int(R.S["turno"]) == 1 and una_volta("mov1"):
				await dici("Tutti gli aerei si sono mossi [b]nello stesso momento[/b]: le manovre sono segrete e simultanee, quindi bisogna prevedere dove sarà il nemico, non dove si trova ora. Il carburante consumato è pari alla velocità della manovra (fase 3).")
		"fine_turno":
			if not io.is_empty() and io["stato"] == "vite" and una_volta("vite"):
				await dici("Sei in [b]avvitamento[/b]! Succede dopo uno stallo o quando ali e coda vengono colpite (con 5 o 6). Ogni turno perdi una quota; nella fase di recupero tiri un dado e con 3-6 riprendi il controllo, puntando in una direzione a caso. Se arrivi a terra, ti schianti.")
			if not io.is_empty() and int(io["carb"]) < 15 and una_volta("carb"):
				await dici("Il [b]carburante[/b] scende: ne restano %d caselle. Le manovre veloci consumano di più. Se il serbatoio si svuota l'aereo plana e deve scendere. Quando sei a corto, conviene uscire dalla mappa dal tuo lato (in basso) per rientrare alla base." % int(io["carb"]))
			for m in io.get("mitra", []):
				if m["inceppata"] and una_volta("inceppata"):
					await dici("Una tua mitragliatrice si è [b]inceppata[/b]: capita dopo una raffica lunga con 5 o 6. Per disincepparla devi eseguire una manovra [b]Avanti non acrobatica[/b]: nella fase di recupero, con 4-6, torna a sparare.")
			if not lui.is_empty() and lui["stato"] == "vite" and una_volta("lui_vite"):
				await dici("L'Albatros è in avvitamento: in questo turno non spara a nessuno e perde quota. Approfittane per metterti in coda!")
		"fine":
			if una_volta("fine"):
				var v: String = R.S["vincitore"]
				var t = "Il duello è finito. "
				if v == "A":
					t += "[b]Complimenti, hai vinto![/b] "
				elif v == "G":
					t += "Questa volta è andata male, ma ogni Asso ha cominciato così. "
				t += "Ora conosci le regole di Blue Max. Prova gli [b]scenari storici[/b] con gli Assi veri, una [b]schermaglia[/b] con amici e telefoni, oppure una [b]campagna[/b] per diventare un Asso e meritare la Blue Max. Puoi sempre rivedere il combattimento con il replay."
				await dici(t)

## Quando si apre la Scheda-Movimento: spiegazioni e manovra consigliata
func scelta_aperta(sm: SchedaMovimento, possibili: Array) -> void:
	if visti.has("*"):
		return
	var R = gioco.R
	var io = _io()
	turno_guidato += 1
	var consiglio = {}
	if int(R.S["turno"]) == 1:
		for m in possibili:
			if m["codice"] == "3A2" and int(m["quota"]) == 0:
				consiglio = m
	if consiglio.is_empty():
		var ia = IA.new(R, "asso")
		var info = {}
		consiglio = ia.scegli_manovra(io, info)
	var c: String = consiglio.get("codice", "")
	if sm.celle.has(c):
		var cel = sm.celle[c]
		cel.scelta = false
		var tw = cel.create_tween().set_loops(4)
		tw.tween_property(cel, "modulate", Color(1.3, 1.1, 0.6), 0.35)
		tw.tween_property(cel, "modulate", Color.WHITE, 0.35)
	if int(R.S["turno"]) == 1 and una_volta("scheda_mov"):
		nota("Questa è la [b]Tabella-Movimento[/b] del tuo Spad VII, uguale a quella di carta. Ogni riquadro è una manovra: la freccia è dove parti, la sagoma dove arrivi e come sarai girato. Il codice, per esempio [b]3A2[/b], dice: manovra numero 3, direzione A (Avanti; S sinistra, D destra), velocità 2. La velocità è anche il carburante consumato e da un turno all'altro può cambiare al massimo di 1. Le manovre sbiadite ora non sono permesse.\n\nPer cominciare scegli [b]3A2[/b] (lampeggia): due esagoni dritto avanti. Toccala, guarda l'anteprima sulla mappa e premi [b]Conferma la manovra[/b].")
	elif int(R.S["turno"]) == 2 and una_volta("quota"):
		nota("Sotto la scheda ci sono i pulsanti della [b]quota[/b]: con la [b]Cabrata[/b] sali di un livello (serve velocità 2 o più, ma non la massima, e costa 1 carburante in più), con la [b]Picchiata[/b] scendi (costa 1 in meno). Stare più in alto del nemico è un vantaggio: chi spara verso il basso ha +1.\n\nDa qui in poi l'istruttore ti fa lampeggiare la manovra che sceglierebbe un Asso. Puoi seguirla o fare di testa tua.")
	elif io["ultima"] != "" and int(Dati.codice(io["ultima"])["n"]) in [2, 3, 4, 5] and possibili.any(func(m): return Dati.geometria(m["codice"])["acrobatica"]) and una_volta("acro"):
		nota("Hai appena volato dritto: ora puoi eseguire le [b]manovre acrobatiche[/b] (dalla 27 alla 36, in fondo alla scheda), come l'[b]Immelmann[/b] (29A2) che ti fa invertire la rotta in un solo esagono. Le manovre tra parentesi, come (31S2), non si possono ripetere due volte di seguito.")
	elif turno_guidato == 4 and una_volta("bordi"):
		nota("Ricorda i [b]bordi della mappa[/b]: si può uscire solo dal proprio lato (per te il bordo in basso), ed è una fuga che chiude la tua partita. Le manovre che ti porterebbero fuori dagli altri bordi non sono permesse.")

func fuoco_aperto(bottoni: Array) -> void:
	if visti.has("*"):
		return
	if una_volta("fuoco"):
		nota("[b]Fase di combattimento![/b] L'Albatros è a tiro: le tue mitragliatrici sparano dritto davanti al muso, fino a 3 esagoni (la linea rossa sulla mappa). Il numero sui pulsanti è il [b]valore di fuoco[/b]: parte dalla distanza (3 esagoni = 2, 2 = 3, 1 = 5, stesso esagono = 7) e cambia con i modificatori: raffica, stabilità del tuo aereo, posizione angolata, bersaglio tallonato, quota... La [b]raffica media[/b] è un buon compromesso: la lunga colpisce di più ma può inceppare le armi. Scegli e premi [b]Fuoco![/b]")
	elif una_volta("fuoco2"):
		nota("Dopo aver sparato si tira un dado: incrociandolo con il valore di fuoco sulla [b]Tabella dei Risultati[/b] si ottengono pedine-danno [color=#2e6aa8]blu[/color] (danni leggeri) e [color=#b8322a]rosse[/color] (danni gravi). Sparare di nuovo allo stesso bersaglio del turno prima dà il bonus «già inquadrato».")
