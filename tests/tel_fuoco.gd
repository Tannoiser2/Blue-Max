extends Node
## Il pilota "telefono" riceve le richieste di manovra e di fuoco e i suoi spari vengono risolti.
var m
func _ready() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(m)
	await get_tree().create_timer(0.5).timeout
	var R = Scenari.schermaglia([{"tipo": "spad13", "nazione": "francia", "controllo": "telefono", "pilota": {"nome": "Lt. Prova"}},
		{"tipo": "fokker_d7", "nazione": "germania", "controllo": "ia", "pilota": {"nome": "Leutnant Test"}}], {"seme": 3}, true)
	var mio := 0
	for a in R.S["aerei"]:
		if a["controllo"] == "telefono":
			a["uid"] = "X"
			mio = a["id"]
	m.avvia_partita(R, {"veloce": true})
	await get_tree().create_timer(0.3).timeout
	var g = m.gioco
	g.rete.codice = "PROV"   # come se la stanza esistesse
	var man := 0
	var fuo := 0
	var spari := 0
	var t := 0
	while t < 6000 and not g.R.S["finita"] and g.R.S["turno"] <= 30:
		await get_tree().create_timer(0.05).timeout
		t += 1
		if t % 400 == 0:
			print("t ", t, " turno ", g.R.S["turno"], " fase ", g.lbl_fase.text, " rich ", g.richieste_tel.keys(), " titolo ", g.titolo_azione.text)
		for c in g.modale.get_children():
			if c is PanelContainer and not (c is FinestraCombattimento):
				g.avanti.emit()
		if g.richieste_tel.has(mio) and not g.dal_telefono.has(mio):
			var r: Dictionary = g.richieste_tel[mio]
			if r["tipo"] == "manovra":
				var s = IA.new(g.R, "asso").scegli_manovra(g.R.aereo(mio), {})
				g._evento_rete({"e": "azione", "k": "manovra", "uid": "X", "p": JSON.stringify({"id": mio, "codice": s["codice"], "quota": int(s["quota"])})})
				man += 1
			else:
				var o = r["opzioni"][0]
				g._evento_rete({"e": "azione", "k": "fuoco", "uid": "X", "p": JSON.stringify({"id": mio, "lista": [{"a": o["a"], "arma": o["arma"], "raffica": "media"}]})})
				fuo += 1
				spari += int(g.dal_telefono.get(mio, []).size())
	print("TELEFONO manovre ", man, " richieste di fuoco ", fuo, " spari accettati ", spari, " turno ", g.R.S["turno"], " finita ", g.R.S["finita"])
	get_tree().quit()
