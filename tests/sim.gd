extends Node
## Partite automatiche IA contro IA: controlla che le regole non si blocchino e stampa le statistiche.
func _ready() -> void:
	var vitt = {"G": 0, "A": 0, "pari": 0}
	var turni = 0
	var n = int(OS.get_environment("PARTITE")) if OS.get_environment("PARTITE") != "" else 20
	for k in n:
		var R: Regole
		var elenco = ["guynemer", "americani", "hawker", "meute", "udet", "libera", "generato"]
		for d in Scenari.STORICI:
			elenco.append(d["id"])
		var sc: String = elenco[k % elenco.size()]
		if sc == "generato":
			var rn = RandomNumberGenerator.new()
			rn.seed = k
			var gsit = Scenari.SITUAZIONI.keys()[k % 5]
			var gg = Scenari.genera(-12 + (k * 7) % 35, 1 + k % 4, 1 + (k + 1) % 4, gsit, rn)
			for x in gg["aerei"]:
				x["controllo"] = "ia"
			R = Scenari.schermaglia(gg["aerei"], {"seme": k, "nuvole": 12}, gg["vicino"])
		elif sc == "libera":
			var lista = []
			for i in 3:
				lista.append({"tipo": ["fokker_d7", "albatros_d5", "fokker_dr1", "pfalz_d12"][i % 4], "nazione": "germania", "controllo": "ia", "pilota": {"nome": "G%d" % i}})
				lista.append({"tipo": ["camel", "spad13", "se5a", "bristol"][i % 4], "nazione": "inghilterra" if i != 1 else "francia", "controllo": "ia", "pilota": {"nome": "A%d" % i}})
			R = Scenari.schermaglia(lista, {"seme": 1000 + k})
		else:
			R = Scenari.costruisci(sc, {"G": "ia", "A": "ia"}, {"seme": 1000 + k})
		var ia_g = IA.new(R, "asso")
		var ia_a = IA.new(R, "veterano")
		var t = 0
		while not R.S["finita"] and t < 60:
			t += 1
			R.calcola_tallonamenti()
			var ordine = R.ordine_scelta()
			var scelte = {}
			var info = {}
			for id in ordine:
				var a = R.aereo(id)
				var ia: IA = ia_g if a["lato"] == "G" else ia_a
				var m = ia.scegli_manovra(a, info)
				scelte[id] = m
				for x in a["tallonato_da"]:
					info[str(id)] = {"dir": Dati.codice(m["codice"])["dir"], "quota": m["quota"]}
			R.applica_scelte(scelte)
			R.fase_carburante()
			R.fase_movimento()
			var att = []
			for a in R.attivi():
				var ia: IA = ia_g if a["lato"] == "G" else ia_a
				att += ia.scegli_attacchi(a)
			R.fase_combattimento(att)
			R.fase_danni()
			R.fase_recupero()
			R.fase_incidenti()
			R.fase_incendi()
			R.fase_spegnimento()
			R.fine_turno()
		turni += t
		var v: String = R.S.get("vincitore", "")
		if v == "":
			v = "pari"
		vitt[v] += 1
		var st: Array = R.S["aerei"].map(func(a): return "%s:%s" % [a["tipo"], a["stato"]])
		print("%-9s turni %2d  vince %-4s %s" % [sc, t, v, " ".join(st)])
	print("vittorie ", vitt, " turni medi ", float(turni) / n)
	get_tree().quit()
