extends Node
## Suoni sintetizzati in Godot (autoload "Suoni"): niente file audio, funzionano sia nel browser sia nell'app.
## raffica corta/media/lunga, motore, vento (scivolata d'aria), fuoco, esplosione, colpo a segno, dado, pedina, avviso.

const RATE := 22050
var banca := {}
var lettori := []
var volume_db := -4.0
var muto := false
var motore_attivo := true
const VOLUME_MOTORE := -20.0

func _ready() -> void:
	var c := ConfigFile.new()
	if c.load("user://suoni.cfg") == OK:
		motore_attivo = c.get_value("suoni", "motore", true)
		muto = not c.get_value("suoni", "effetti", true)
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		lettori.append(p)
	_crea()

func _salva() -> void:
	var c := ConfigFile.new()
	c.set_value("suoni", "motore", motore_attivo)
	c.set_value("suoni", "effetti", not muto)
	c.save("user://suoni.cfg")

func imposta_motore(x: bool) -> void:
	motore_attivo = x
	_salva()

func imposta_effetti(x: bool) -> void:
	muto = not x
	_salva()

## Il motore in sottofondo durante il movimento: più acuto con la velocità, sale di giri in cabrata,
## cala in picchiata e nelle acrobazie fa un «ululato»; si toglie dal menu.
func motore(codice: String, dq: float) -> void:
	if not motore_attivo or codice == "":
		return
	var k := Dati.codice(codice)
	var nome := "motore"
	if int(k["n"]) >= 27:
		nome = "motore_acro"
	elif dq > 0.01:
		nome = "motore_su"
	elif dq < -0.01:
		nome = "motore_giu"
	var tono := 0.75 + 0.12 * float(k["vel"])
	_play(nome, VOLUME_MOTORE, tono)

func suona(n: String, vol := 0.0, tono := 1.0) -> void:
	if muto:
		return
	_play(n, vol, tono)

func _play(n: String, vol: float, tono: float) -> void:
	if not banca.has(n):
		return
	var libero: AudioStreamPlayer = null
	for p in lettori:
		if not p.playing:
			libero = p
			break
	if libero == null:
		libero = lettori[0]
	libero.stream = banca[n]
	libero.volume_db = volume_db + vol
	libero.pitch_scale = tono
	libero.play()

func _wav(dati: PackedFloat32Array) -> AudioStreamWAV:
	var b := PackedByteArray()
	b.resize(dati.size() * 2)
	for i in dati.size():
		var v := int(clampf(dati[i], -1.0, 1.0) * 32000.0)
		b.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = b
	return w

func _crea() -> void:
	var rn := RandomNumberGenerator.new()
	rn.seed = 1917
	# un colpo di mitragliatrice: schiocco di rumore filtrato + tonfo basso
	var colpo := func(buf: PackedFloat32Array, inizio: int, forza: float) -> void:
		var lp := 0.0
		for i in int(RATE * 0.07):
			var t := float(i) / RATE
			var env := exp(-t * 55.0)
			lp += (rn.randf_range(-1, 1) - lp) * 0.55
			var v := lp * env * 0.9 + sin(TAU * 95.0 * t) * exp(-t * 40.0) * 0.6
			if inizio + i < buf.size():
				buf[inizio + i] += v * forza
	for k in [["raffica_corta", 4], ["raffica_media", 8], ["raffica_lunga", 14]]:
		var n: int = k[1]
		var buf := PackedFloat32Array()
		buf.resize(int(RATE * (n * 0.085 + 0.25)))
		for j in n:
			colpo.call(buf, int(j * 0.085 * RATE) + rn.randi_range(0, 120), rn.randf_range(0.75, 1.0))
		banca[k[0]] = _wav(buf)
	# motore rotativo: dente di sega che sale e scende, con battito
	var m := PackedFloat32Array()
	m.resize(int(RATE * 1.6))
	var fase := 0.0
	for i in m.size():
		var t := float(i) / RATE
		var f := 62.0 + 18.0 * sin(t * 2.2)
		fase += f / RATE
		var saw := fmod(fase, 1.0) * 2.0 - 1.0
		var batt := 0.6 + 0.4 * sin(TAU * 11.0 * t)
		var env := minf(1.0, t * 4.0) * minf(1.0, (1.6 - t) * 3.0)
		m[i] = saw * batt * env * 0.35
	banca["motore"] = _wav(m)
	for v in [["motore_su", 0.35], ["motore_giu", -0.3], ["motore_acro", 0.0]]:
		var mm := PackedFloat32Array()
		mm.resize(int(RATE * 1.6))
		var fs := 0.0
		for i in mm.size():
			var t := float(i) / RATE
			var f := 62.0 * (1.0 + float(v[1]) * t / 1.6)
			if v[0] == "motore_acro":
				f = 62.0 * (1.0 + 0.45 * sin(PI * t / 1.6))
			fs += f / RATE
			var saw := fmod(fs, 1.0) * 2.0 - 1.0
			var env := minf(1.0, t * 4.0) * minf(1.0, (1.6 - t) * 3.0)
			mm[i] = saw * (0.6 + 0.4 * sin(TAU * 11.0 * t)) * env * 0.35
		banca[v[0]] = _wav(mm)
	# vento: rumore che cresce e cala con un filtro che si apre (la scivolata d'aria)
	var w := PackedFloat32Array()
	w.resize(int(RATE * 1.4))
	var lp := 0.0
	for i in w.size():
		var t := float(i) / w.size()
		var a := 0.04 + 0.5 * sin(PI * t)
		lp += (rn.randf_range(-1, 1) - lp) * a
		w[i] = lp * sin(PI * t) * 0.9
	banca["vento"] = _wav(w)
	# fuoco: crepitio
	var fu := PackedFloat32Array()
	fu.resize(int(RATE * 1.5))
	lp = 0.0
	for i in fu.size():
		var t := float(i) / RATE
		lp += (rn.randf_range(-1, 1) - lp) * 0.08
		var cr := 0.0
		if rn.randf() < 0.004:
			cr = rn.randf_range(-1, 1)
		fu[i] = (lp * 0.5 + cr) * minf(1.0, t * 5.0) * minf(1.0, (1.5 - t) * 3.0)
	banca["fuoco"] = _wav(fu)
	# esplosione: tonfo profondo e rumore lungo
	var e := PackedFloat32Array()
	e.resize(int(RATE * 1.8))
	lp = 0.0
	for i in e.size():
		var t := float(i) / RATE
		lp += (rn.randf_range(-1, 1) - lp) * 0.12
		e[i] = (lp * 1.6 + sin(TAU * (55.0 - 25.0 * t) * t) * 0.9) * exp(-t * 2.2)
	banca["esplosione"] = _wav(e)
	# colpo a segno: schianto secco di legno e tela
	var c := PackedFloat32Array()
	c.resize(int(RATE * 0.3))
	for i in c.size():
		var t := float(i) / RATE
		c[i] = rn.randf_range(-1, 1) * exp(-t * 18.0) * 0.8 + sin(TAU * 180.0 * t) * exp(-t * 25.0) * 0.4
	banca["colpito"] = _wav(c)
	# dado che rotola: clic irregolari
	var d := PackedFloat32Array()
	d.resize(int(RATE * 0.8))
	for k2 in 7:
		var s := int((0.05 + k2 * 0.1 + rn.randf() * 0.03) * RATE)
		for i in int(RATE * 0.02):
			if s + i < d.size():
				d[s + i] += rn.randf_range(-1, 1) * exp(-float(i) / RATE * 300.0) * 0.7
	banca["dado"] = _wav(d)
	# pedina girata
	var p := PackedFloat32Array()
	p.resize(int(RATE * 0.12))
	for i in p.size():
		var t := float(i) / RATE
		p[i] = sin(TAU * 900.0 * t) * exp(-t * 60.0) * 0.4 + rn.randf_range(-1, 1) * exp(-t * 90.0) * 0.3
	banca["pedina"] = _wav(p)
	# avviso (tocca a te)
	var o := PackedFloat32Array()
	o.resize(int(RATE * 0.35))
	for i in o.size():
		var t := float(i) / RATE
		var f := 660.0 if t < 0.15 else 880.0
		o[i] = sin(TAU * f * t) * 0.3 * exp(-fmod(t, 0.15) * 10.0)
	banca["avviso"] = _wav(o)
