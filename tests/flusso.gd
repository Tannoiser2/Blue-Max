extends Node
## Gioca da solo tutorial e campagna (risponde l'IA al posto del giocatore) e controlla che arrivino in fondo.
var m
func _ready() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(m)
	await get_tree().create_timer(0.5).timeout
	var cosa := OS.get_environment("COSA")
	if cosa == "campagna":
		await campagna()
	else:
		m.menu._tutorial()
		await gioca(200)
		print("TUTORIAL finito: ", m.gioco.R.S["finita"], " turni ", m.gioco.R.S["turno"], " vincitore ", m.gioco.R.S["vincitore"])
	get_tree().quit()

func gioca(maxt: int) -> void:
	var g: Gioco = m.gioco
	g.veloce = true
	var t := 0
	while t < maxt * 40 and not g.R.S["finita"]:
		await get_tree().create_timer(0.05).timeout
		t += 1
		if g.tutorial and g.tutorial.pannello.visible:
			g.tutorial.ok.emit()
		for c in g.modale.get_children():
			if c is PanelContainer and not (c is FinestraCombattimento):
				g.avanti.emit()
		if g.titolo_azione.text.begins_with("Manovra"):
			var a: Dictionary = {}
			for x in g.R.S["aerei"]:
				if x["controllo"] == "umano" and g.titolo_azione.text.ends_with(x["pilota"]):
					a = x
			if not a.is_empty():
				g.scelta_fatta.emit(IA.new(g.R, "asso").scegli_manovra(a, {}))
		elif g.titolo_azione.text.begins_with("Fuoco"):
			for x in g.R.S["aerei"]:
				if x["controllo"] == "umano" and g.titolo_azione.text.ends_with(x["pilota"]):
					g.fuoco_fatto.emit(IA.new(g.R, "asso").scegli_attacchi(x))
	await get_tree().create_timer(1.0).timeout

func campagna() -> void:
	m.menu._campagna()
	await get_tree().process_frame
	var c: Campagna = m.menu.contenuto.get_child(0)
	c.C = {"codice": "PROVAX", "nazione": "inghilterra", "lato": "A", "mese": 7, "settimana": 0, "gregari": 1, "livello": "veterano", "caduti": [],
		"pilota": c._nuovo_pilota("Prova"), "registro": []}
	c.C["pilota"]["aereo"] = c._aerei_disponibili()[0]
	print("aerei disponibili agosto 1917: ", c._aerei_disponibili())
	for k in 3:
		c.scheda_volo()
		c.missione()
		await get_tree().process_frame
		await gioca(60)
		var R: Regole = m.gioco.R
		print("missione ", k + 1, " finita ", R.S["finita"], " turni ", R.S["turno"])
		m.gioco.uscita.emit()
		await get_tree().create_timer(0.3).timeout
		c = m.menu.contenuto.get_child(0)
		print("pilota ", c.C["pilota"]["nome"], " esperienza ", c.C["pilota"]["esperienza"], " abbattimenti ", c.C["pilota"]["abbattimenti"], " mese ", c.C["mese"], " sett ", c.C["settimana"])
