class_name SchedaAereo
extends Control
## La Scheda-Aereo: caselle di ali, fusoliera, coda, motore e carburante annerite come sulla carta,
## mitragliatrici, caricatori della Lewis, osservatore ed effetti in corso.

var R: Regole
var aereo: Dictionary = {}
var segreto = false   # danni del nemico nascosti

func imposta(r: Regole, a: Dictionary, nascondi := false) -> void:
	R = r
	aereo = a
	segreto = nascondi
	custom_minimum_size = Vector2(360, _altezza())
	queue_redraw()

func _altezza() -> float:
	if aereo.is_empty():
		return 100
	var t: Dictionary = Dati.aerei[aereo["tipo"]]
	var h = 92.0
	for k in ["ali", "fusoliera", "coda", "motore", "carburante"]:
		h += 22.0 + ceil(float(t[k]) / 20.0) * 15.0
	h += 70
	return h

func _draw() -> void:
	if aereo.is_empty():
		return
	var a = aereo
	var t: Dictionary = Dati.aerei[a["tipo"]]
	var f = Tema.font("grassetto")
	var fb = Tema.font("testo")
	var ft = Tema.font("titolo")
	draw_rect(Rect2(Vector2.ZERO, size), Color("efe5cc"))
	draw_rect(Rect2(Vector2.ZERO, size), Tema.SEPPIA, false, 2.0)
	var col = Tema.colore_lato(a["lato"])
	_coccarda(Vector2(34, 36), 22, a["nazione"])
	draw_string(ft, Vector2(66, 32), t["nome"], HORIZONTAL_ALIGNMENT_LEFT, size.x - 72, 26, Tema.INCHIOSTRO)
	var stato_txt = {"volo": "", "vite": "IN AVVITAMENTO", "planata": "", "abbattuto": "ABBATTUTO", "fuggito": "RIENTRATO", "atterrato": "ATTERRATO", "catturato": "CATTURATO"}.get(a["stato"], "")
	var riga2: String = a["pilota"]
	if a["asso"]:
		riga2 += " - Asso"
	elif a["novellino"]:
		riga2 += " - novellino"
	draw_string(fb, Vector2(66, 56), riga2, HORIZONTAL_ALIGNMENT_LEFT, size.x - 72, 18, Tema.SEPPIA)
	var y = 78.0
	var info = "Stabilità %s   Quota %s   Ultima %s" % [R.stabilita(a) if R else t["stabilita"], Dati.QUOTE[int(a["quota"])], a["ultima"] if a["ultima"] != "" else "-"]
	draw_string(fb, Vector2(12, y), info, HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 17, Tema.INCHIOSTRO)
	y += 12
	var righe = [["Ali", "ali", "ali"], ["Fusoliera", "fusoliera", "fus"], ["Coda", "coda", "coda"], ["Motore", "motore", "motore"], ["Carburante", "carburante", "carb"]]
	for rr in righe:
		var tot: int = int(t[rr[1]])
		var rest: int = int(a[rr[2]])
		if segreto and rr[2] != "carb":
			rest = -1
		if segreto and rr[2] == "carb":
			rest = -1
		y += 20
		draw_string(f, Vector2(12, y), rr[0], HORIZONTAL_ALIGNMENT_LEFT, 120, 17, Tema.INCHIOSTRO)
		var testo = "%d / %d" % [rest, tot] if rest >= 0 else "? / %d" % tot
		draw_string(fb, Vector2(size.x - 80, y), testo, HORIZONTAL_ALIGNMENT_RIGHT, 70, 16, Tema.SEPPIA)
		y += 4
		var q = 14.0
		for i in tot:
			var cx = 12.0 + (i % 20) * (q + 2.5)
			var cy = y + floor(i / 20.0) * (q + 1)
			var re = Rect2(cx, cy, q, q)
			draw_rect(re, Color("fbf6ea"))
			draw_rect(re, Tema.SEPPIA, false, 1.0)
			if rest >= 0 and i >= rest:
				var c = Tema.ROSSO if rr[2] != "carb" else Color("4b4b4b")
				draw_line(re.position + Vector2(2, 2), re.end - Vector2(2, 2), c, 2.0)
				draw_line(Vector2(re.position.x + 2, re.end.y - 2), Vector2(re.end.x - 2, re.position.y + 2), c, 2.0)
			if i > 0 and i % 5 == 0 and i % 20 != 0:
				draw_line(Vector2(cx - 1.5, cy), Vector2(cx - 1.5, cy + q), Tema.INCHIOSTRO, 1.0)
		y += ceil(tot / 20.0) * (q + 1)
	# armi
	y += 22
	var armi = []
	for m in a["mitra"]:
		var s = "Lewis" if m["lewis"] else "Mitragliatrice"
		if m["distrutta"]:
			s += " distrutta"
		elif m["inceppata"]:
			s += " INCEPPATA"
		elif m["lewis"]:
			s += " (%d caricatori)" % m["caricatori"].size()
		armi.append(s)
	if not a["oss"].is_empty():
		var o: Dictionary = a["oss"]
		var s = "Osservatore"
		if not o["vivo"]:
			s += " ucciso"
		elif int(o["ferito"]) > 0:
			s += " ferito (%d)" % int(o["ferito"])
		elif o["inceppata"]:
			s += ": arma inceppata"
		armi.append(s)
	if segreto:
		armi = ["Armi: segrete"]
	draw_string(fb, Vector2(12, y), ", ".join(armi), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 16, Tema.INCHIOSTRO)
	y += 22
	var eff = []
	if a["fuoco"]:
		eff.append("IN FIAMME")
	if a["fumo"]:
		eff.append("perde fumo")
	if stato_txt != "":
		eff.append(stato_txt)
	if not segreto:
		if a["stato"] == "planata":
			eff.append("in planata")
		if not a["timone"].is_empty():
			eff.append("timone: solo %s (%d)" % [{"D": "Destra", "S": "Sinistra", "A": "Avanti"}[a["timone"]["dir"]], int(a["timone"]["turni"])])
		if a["no_acro"]:
			eff.append("niente acrobazie")
		if a["no_veloce"]:
			eff.append("niente velocità 3-4")
		if a["ferito_lento"] or a["ferito_avanti"]:
			eff.append("pilota ferito")
		if int(a["obbligo"]) == 1:
			eff.append("deve cabrare")
		elif int(a["obbligo"]) == -1:
			eff.append("deve picchiare")
		if a["stallo"]:
			eff.append("in stallo")
	if eff.is_empty():
		eff.append("nessun effetto in corso")
	draw_string(f, Vector2(12, y), ", ".join(eff), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 16, Tema.ROSSO if eff.size() > 0 and eff[0] != "nessun effetto in corso" else Tema.SEPPIA)

func _coccarda(c: Vector2, r: float, nazione: String) -> void:
	match nazione:
		"germania":
			draw_rect(Rect2(c - Vector2(r, r), Vector2(r, r) * 2), Color("f4f0e6"))
			var k = r * 0.85
			var w = r * 0.32
			draw_colored_polygon(PackedVector2Array([c + Vector2(-w, -k), c + Vector2(w, -k), c + Vector2(w * 0.6, -w), c + Vector2(k, -w), c + Vector2(k, w), c + Vector2(w * 0.6, w),
				c + Vector2(w, k), c + Vector2(-w, k), c + Vector2(-w * 0.6, w), c + Vector2(-k, w), c + Vector2(-k, -w), c + Vector2(-w * 0.6, -w)]), Color("141414"))
		"inghilterra":
			draw_circle(c, r, Color("1f3f8a"))
			draw_circle(c, r * 0.66, Color("f4f0e6"))
			draw_circle(c, r * 0.33, Color("b8221e"))
		"francia":
			draw_circle(c, r, Color("b8221e"))
			draw_circle(c, r * 0.66, Color("f4f0e6"))
			draw_circle(c, r * 0.33, Color("1f3f8a"))
		"usa":
			draw_circle(c, r, Color("b8221e"))
			draw_circle(c, r * 0.66, Color("1f3f8a"))
			draw_circle(c, r * 0.33, Color("f4f0e6"))
