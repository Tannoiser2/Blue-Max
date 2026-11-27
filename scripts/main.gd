extends Node
## Avvio: menu, partite, tutorial, campagna. Il mondo 3D resta sempre sotto l'interfaccia.

var mondo: Mondo
var ui: CanvasLayer
var radice: Control
var rete: Rete
var gioco: Gioco
var menu: Menu

func _ready() -> void:
	rete = Rete.new()
	rete.name = "Rete"
	add_child(rete)
	mondo = Mondo.new()
	add_child(mondo)
	ui = CanvasLayer.new()
	add_child(ui)
	radice = Control.new()
	radice.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	radice.theme = Tema.tema()
	radice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(radice)
	var p = rete.parametri()
	if p.has("prova"):
		_prova(p["prova"], p)
		return
	mostra_menu()
	if p.has("entra"):
		menu.entra_online()
		rete.entra(str(p["entra"]).to_upper(), str(p.get("nome", "Ospite")))

func mostra_menu() -> void:
	if gioco:
		gioco.queue_free()
		gioco = null
	mondo.R = null
	for k in mondo.nodi:
		mondo.nodi[k]["radice"].queue_free()
		mondo.nodi[k]["colonna"].queue_free()
		mondo.nodi[k]["anello"].queue_free()
	mondo.nodi.clear()
	for k in mondo.etichette:
		mondo.etichette[k].queue_free()
	mondo.etichette.clear()
	mondo.pulisci_segni()
	mondo.pulisci_evid()
	menu = Menu.new()
	menu.principale = self
	radice.add_child(menu)

func avvia_partita(R: Regole, opz := {}) -> void:
	if menu:
		menu.queue_free()
		menu = null
	gioco = Gioco.new()
	radice.add_child(gioco)
	gioco.uscita.connect(_fine_partita.bind(opz))
	gioco.avvia(R, mondo, rete, opz)

func avvia_ospite(S: Dictionary, seq := 0) -> void:
	if menu:
		menu.queue_free()
		menu = null
	gioco = Gioco.new()
	radice.add_child(gioco)
	gioco.uscita.connect(func(): rete.chiudi(); mostra_menu())
	gioco.avvia_ospite(S, mondo, rete, seq)

func _fine_partita(opz: Dictionary) -> void:
	var camp: Dictionary = opz.get("campagna", {})
	if not camp.is_empty() and gioco and gioco.R:
		var R = gioco.R
		var storia = gioco.storia.size()
		mostra_menu()
		menu.ritorno_campagna(camp, R, storia)
		return
	mostra_menu()

func _unhandled_input(ev: InputEvent) -> void:
	if gioco == null and mondo and menu and menu.visible == false:
		mondo.gestisci_input(ev)

## Partite di prova per le foto e i test automatici (?prova=...)
func _prova(cosa: String, par := {}) -> void:
	if cosa != "telefono":
		var R0 = Scenari.costruisci("meute", {"G": "ia", "A": "ia"}, {"seme": 5})
		avvia_partita(R0, {"veloce": true})
		return
	var R = Scenari.schermaglia([{"tipo": "spad13", "nazione": "francia", "controllo": "telefono", "pilota": {"nome": "Lt. Prova"}},
		{"tipo": "fokker_d7", "nazione": "germania", "controllo": "ia", "pilota": {"nome": "Leutnant Test"}}], {"seme": 11}, true)
	if par.has("dietro"):
		# lo Spad del telefono parte in coda al Fokker: serve a provare il fuoco dal telefono
		for a in R.S["aerei"]:
			a["prua"] = 5
			a["quota"] = 2
			if a["lato"] == "G":
				a["q"] = 1; a["r"] = 7
			else:
				a["q"] = 0; a["r"] = 8
	rete.avvia()
	while true:
		var e = await rete.evento
		if e.get("e") == "stanza":
			print("STANZA ", e["codice"])
		if e.get("e") == "entra":
			for a in R.S["aerei"]:
				if a["controllo"] == "telefono":
					a["uid"] = e["uid"]
					a["giocatore"] = e.get("nome", "")
			break
	avvia_partita(R, {"veloce": true})
