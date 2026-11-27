extends Node
func _ready() -> void:
	var zero = []
	for t in Dati.aerei:
		var R = Scenari.schermaglia([{"tipo": t, "nazione": "germania" if Dati.aerei[t].get("lato", "G") == "G" else "francia", "controllo": "ia", "pilota": {"nome": "x"}}, {"tipo": "camel", "nazione": "inghilterra", "controllo": "ia", "pilota": {"nome": "y"}}], {"seme": 1}, true)
		var a = R.S["aerei"][0]
		var b = R.S["aerei"][1]
		a["q"] = 0; a["r"] = 8; a["prua"] = 5; a["quota"] = 2
		b["q"] = 2; b["r"] = 6; b["prua"] = 5; b["quota"] = 2
		var x = R.puo_sparare(a, b)
		if x.is_empty():
			zero.append([t, R._armi_pilota_pronte(a), a["stato"], a["fuoco"]])
	print("TIRO senza fuoco possibile: ", zero)
	get_tree().quit()
