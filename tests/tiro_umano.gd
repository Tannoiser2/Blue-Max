extends Node
## Un umano in coda al nemico: il gioco deve chiedergli di sparare ogni volta che può
var m
func _ready() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(m)
	await get_tree().create_timer(0.5).timeout
	var R = Scenari.schermaglia([{"tipo": "spad13", "nazione": "francia", "controllo": "umano", "pilota": {"nome": "Lt. Prova"}},
		{"tipo": "fokker_d7", "nazione": "germania", "controllo": "ia", "pilota": {"nome": "Leutnant Test"}}], {"seme": int(OS.get_environment("SEME") if OS.get_environment("SEME") != "" else "3")}, true)
	var mio := 0
	for a in R.S["aerei"]:
		a["prua"] = 5; a["quota"] = 2
		if a["controllo"] == "umano":
			mio = a["id"]; a["q"] = 0; a["r"] = 8
		else:
			a["q"] = 1; a["r"] = 7
	m.avvia_partita(R, {"veloce": true, "livelli": {"G": "recluta", "A": "recluta"}})
	await get_tree().create_timer(0.3).timeout
	var g = m.gioco
	var chiesto := 0
	var possibile := 0
	var turno_visto := -1
	var t := 0
	while t < 5000 and not g.R.S["finita"] and g.R.S["turno"] <= 25:
		await get_tree().create_timer(0.04).timeout
		t += 1
		for c in g.modale.get_children():
			if c is PanelContainer and not (c is FinestraCombattimento):
				g.avanti.emit()
		var me = g.R.aereo(mio)
		if int(g.R.S.get("fase", -1)) == 4 and turno_visto != g.R.S["turno"]:
			turno_visto = g.R.S["turno"]
			for b in g.R.nemici(me):
				if not g.R.puo_sparare(me, b).is_empty():
					possibile += 1
					print("turno ", g.R.S["turno"], " posso sparare a distanza ", g.R.puo_sparare(me, b))
		var tit: String = g.titolo_azione.text
		if tit.begins_with("Fuoco di"):
			chiesto += 1
			var o = g._opzioni_fuoco(me)[0]
			g.fuoco_fatto.emit([{"da": mio, "a": o["a"], "arma": o["arma"], "raffica": "media"}])
			await get_tree().create_timer(0.1).timeout
		elif tit.begins_with("Manovra di") or tit.contains("anovra"):
			var s = IA.new(g.R, "asso").scegli_manovra(me, {})
			var pos = g.R.manovre_possibili(me)
			var sc = pos[0]
			for x in pos:
				if x["codice"] == s["codice"] and int(x["quota"]) == int(s["quota"]):
					sc = x
			g.scelta_fatta.emit(sc)
			await get_tree().create_timer(0.1).timeout
	print("UMANO possibile ", possibile, " chiesto ", chiesto, " turno ", g.R.S["turno"], " titolo ", g.titolo_azione.text)
	get_tree().quit()
