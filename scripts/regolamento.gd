class_name Regolamento
extends Control
## Il regolamento a schede, consultabile durante la partita.

const SEZIONI := [
	["Il gioco", "[b]Blue Max[/b] simula i duelli aerei della Prima Guerra Mondiale sul Fronte Occidentale (1917-1918). Ogni giocatore è un pilota: Alleati (Inghilterra, Francia, Stati Uniti) contro Tedeschi.\n\nLa mappa è divisa in esagoni. Ogni aereo sta al centro di un esagono con la prua rivolta verso un lato. Le manovre si scrivono in segreto e si eseguono tutte insieme.\n\nLa partita termina quando tutti gli aerei di una squadra sono stati abbattuti o sono scappati."],
	["Sequenza del turno", "1. [b]Tallonamento[/b]: chi sta in coda a un nemico lo tallona.\n2. [b]Scelta della manovra[/b]: ognuno sceglie in segreto la manovra; chi è tallonato rivela la direzione (A, S o D) e il cambio di quota a chi lo tallona.\n3. [b]Consumo di carburante[/b]: si cancellano tante caselle quanto la velocità della manovra.\n4. [b]Movimento[/b]: tutti muovono insieme.\n5. [b]Combattimento[/b]: chi ha un bersaglio a tiro spara.\n6. [b]Risoluzione dei danni[/b]: i danni hanno effetto.\n7. [b]Recupero[/b]: si disinceppano le mitragliatrici e si tenta di uscire dall'avvitamento.\n8. [b]Incidenti[/b]: chi ha sparato una raffica lunga controlla se le armi si inceppano; chi è in avvitamento perde quota.\n9. [b]Danni da incendio[/b]: chi brucia estrae una pedina-danno blu.\n10. [b]Spegnimento[/b]: si tenta di spegnere incendi e fumo."],
	["Manovre", "Ogni aereo ha la sua Tabella-Movimento. Il codice, per esempio [b]20D3[/b], indica il numero della manovra, la direzione (A avanti, S sinistra, D destra) e la velocità, che è anche il carburante consumato.\n\n[b]Accelerazione[/b]: la velocità può cambiare al massimo di un punto da un turno all'altro.\n[b]Acrobatiche[/b] (27-36): solo dopo una manovra Avanti 2, 3, 4 o 5.\n[b]Non ripetibili[/b] (1, 28, 31, 36, tra parentesi): non due volte di seguito.\n[b]Carburante[/b]: non si può scegliere una manovra che consuma più carburante di quello rimasto. Senza carburante o senza motore si plana: solo manovre 2 o 9, scendendo di quota.\n[b]Bordi[/b]: si esce dalla mappa solo dal proprio lato (dietro la propria linea di partenza): è la fuga."],
	["Quota di volo", "Cinque quote: Molto Bassa, Bassa, Media, Alta, Molto Alta.\n[b]Picchiata[/b]: con velocità 2 o più si scende di una quota e si consuma una casella in meno.\n[b]Cabrata[/b]: con una manovra non acrobatica di velocità 2 o più, ma inferiore di almeno 1 alla massima dell'aereo, si sale di una quota e si consuma una casella in più.\nChi lascia la quota massima non può più tornarci (tranne gli aerei con il «+»).\n[b]Atterraggio[/b]: a quota Molto Bassa si atterra con una picchiata dopo una manovra Avanti. Picchiare da Molto Bassa altrimenti vuol dire schiantarsi.\nSi spara e si tallona solo alla stessa quota o a quella adiacente."],
	["Tallonamento", "Si tallona un aereo se è nel proprio arco frontale entro 3 esagoni e noi siamo nel suo arco posteriore. Nello stesso esagono serve la stessa direzione e una velocità inferiore nel turno precedente.\nChi è tallonato rivela la direzione della manovra (e se sale o scende) a chi lo tallona.\nNon si tallona chi brucia o perde fumo; i novellini non tallonano i nemici."],
	["Combattimento", "Si spara dritto davanti al muso, fino a 3 esagoni, senza attraversare esagoni con altri aerei. Un solo attacco per turno.\n[b]Valore di base[/b]: distanza 3 = 2, 2 = 3, 1 = 5, stesso esagono = 7.\n[b]Modificatori[/b]: raffica media o lunga, stabilità, bersaglio in stallo, velocità 3-4 dell'attaccante, una sola mitragliatrice, posizione angolata (il bersaglio non punta nella nostra stessa direzione né in quella opposta), bersaglio già inquadrato, bersaglio tallonato, bersaglio più in basso.\nSi tira un dado e si incrocia con il valore di fuoco sulla Tabella dei Risultati: B = pedina-danno blu (leggera), R = rossa (grave).\nMedia o lunga contro un aereo più in alto obbliga a cabrare il turno dopo; più in basso, a picchiare."],
	["Danni", "Le pedine-danno tolgono caselle di ali, fusoliera, coda e motore, o hanno effetti speciali: serbatoio colpito, esplosione, timone inceppato, pilota ferito, fumo, fuoco, mitragliatrice distrutta, osservatore ucciso o ferito, ala lacerata, motore colpito.\nAlla stessa quota un colpo frontale trasforma i danni alla coda in danni al motore; un colpo da dietro trasforma i danni al motore in danni alla coda.\nChi ha preso colpi alle ali o alla coda va in avvitamento con 5 o 6. Senza ali, coda o fusoliera si precipita. Senza motore o carburante si plana.\nI danni sono segreti: si vedono solo fumo, fuoco, l'osservatore ucciso e l'abbattimento."],
	["Avvitamento, stallo, incendi", "[b]Stallo[/b]: la manovra 1 o il tentativo di salire oltre la quota massima; va in avvitamento con 5 o 6.\n[b]Avvitamento[/b]: manovra 0A2 obbligata, si perde una quota a turno; si esce con 3-6 (novellino 4-6) puntando in una direzione a caso.\n[b]Inceppamento[/b]: dopo una raffica lunga con 5 o 6; si disinceppa con 4-6 eseguendo una manovra Avanti non acrobatica.\n[b]Fuoco[/b]: una pedina blu a ogni turno; si spegne con 5-6 (4-6 con le manovre 8, 16, 17). Chi brucia non spara, non tallona e non fa acrobazie.\n[b]Fumo[/b]: si dirada con 6; con 1 diventa fuoco."],
	["Lewis e osservatori", "[b]Mitragliatrice Lewis[/b] (S.E.5a, Bristol): caricatori da 5 caselle; corta 1, media 2, lunga 3. Si cambia caricatore con una manovra 2, 3, 4 o 5 (non si spara quel turno).\n[b]Osservatori[/b] (Halberstadt CL.II, Bristol F.2B): sparano in tutto l'arco posteriore tranne l'esagono subito dietro (punto cieco), anche a un bersaglio diverso da quello del pilota; possono sparare anche se l'aereo brucia."],
	["Piloti e campagna", "[b]Esperienza[/b]: 1 punto per ogni turno sulla mappa, 25 per ogni abbattimento.\n[b]Novellino[/b] (meno di 50 punti): niente tallonamento dei nemici e niente acrobazie; va in avvitamento con 4-6.\n[b]Veterano[/b]: 50 punti o più. [b]Asso[/b]: almeno 5 abbattimenti.\nA 100, 200, 350, 500, 1000 punti e al quinto abbattimento si ottiene un'abilità: Manovre Evasive, Manovre Acrobatiche, Tallonare, Stabilità, Bonus al Tiro, Inceppamenti, Tiro Angolato, Mira e Portata Estesa (solo Assi).\nLa campagna va da gennaio 1917 a novembre 1918, quattro missioni al mese; gli aerei disponibili seguono la Tabella della disponibilità storica."],
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var velo = ColorRect.new()
	velo.color = Color(0, 0, 0, 0.6)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var c = CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var p = Tema.pannello(Tema.CARTA, Tema.SEPPIA, 18)
	p.custom_minimum_size = Vector2(1100, 760)
	c.add_child(p)
	var v = VBoxContainer.new()
	p.add_child(v)
	v.add_child(Tema.titolo("Regolamento di Blue Max", 40, Tema.ROSSO))
	var h = HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	var indice = VBoxContainer.new()
	indice.custom_minimum_size.x = 290
	h.add_child(indice)
	var testo = RichTextLabel.new()
	testo.bbcode_enabled = true
	testo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	testo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	testo.add_theme_font_size_override("normal_font_size", 22)
	testo.add_theme_font_size_override("bold_font_size", 22)
	h.add_child(testo)
	for s in SEZIONI:
		var b = Tema.bottone(s[0], func(): testo.text = "[font_size=30][b]%s[/b][/font_size]\n\n%s" % [s[0], s[1]], 19, 280)
		indice.add_child(b)
	testo.text = "[font_size=30][b]%s[/b][/font_size]\n\n%s" % [SEZIONI[0][0], SEZIONI[0][1]]
	v.add_child(Tema.bottone("Chiudi", queue_free, 22))
