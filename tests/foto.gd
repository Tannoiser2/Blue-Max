extends Node
## Foto dell'interfaccia: avvia il gioco vero e salva schermate in user://foto (o in FOTO_DIR).
var dir := "/tmp/foto"
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var cosa := OS.get_environment("COSA")
	if cosa == "":
		cosa = "menu"
	var m = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(m)
	await get_tree().create_timer(1.5).timeout
	match cosa:
		"menu":
			await foto("menu")
			m.menu.schermaglia()
			await get_tree().create_timer(0.8).timeout
			await foto("schermaglia")
			m.menu.scenari()
			await get_tree().create_timer(0.8).timeout
			await foto("scenari")
			m.menu.generatore()
			await get_tree().create_timer(0.8).timeout
			await foto("generatore")
			m.menu.online()
			await get_tree().create_timer(0.8).timeout
			await foto("online")
			m.menu.crediti()
			await get_tree().create_timer(0.5).timeout
			await foto("crediti")
		"partita":
			var R := Scenari.costruisci("meute", {"G": "ia", "A": "umano"}, {"seme": 3})
			m.avvia_partita(R, {})
			await get_tree().create_timer(4.0).timeout
			await foto("scelta")
			# sceglie la prima manovra possibile
			var g: Gioco = m.gioco
			var a := R.aereo(2)
			var pos := R.manovre_possibili(a)
			for x in g.corpo_azione.find_children("*", "SchedaMovimento", true, false):
				x.scelta.emit("3A2")
			await get_tree().create_timer(0.8).timeout
			await foto("anteprima")
			g.scelta_fatta.emit(pos[0])
			await get_tree().create_timer(2.0).timeout
			await foto("movimento")
			var t := 0
			while t < 40 and not R.S["finita"]:
				await get_tree().create_timer(0.5).timeout
				t += 1
				if g.corpo_azione.get_child_count() > 0 and g.titolo_azione.text.begins_with("Manovra"):
					await foto("scelta2")
					var p2 := R.manovre_possibili(a)
					var ia := IA.new(R, "asso")
					g.scelta_fatta.emit(ia.scegli_manovra(a, {}))
				if g.titolo_azione.text.begins_with("Fuoco"):
					await foto("fuoco")
					var ia := IA.new(R, "asso")
					g.fuoco_fatto.emit(ia.scegli_attacchi(a))
					await get_tree().create_timer(2.2).timeout
					await foto("combattimento")
		"striscia":
			var R = Scenari.costruisci("meute", {"G": "ia", "A": "ia"}, {"seme": 3})
			m.avvia_partita(R, {})
			var g: Gioco = m.gioco
			var n = 0
			var t = 0
			while n < 6 and t < 600:
				await get_tree().create_timer(0.25).timeout
				t += 1
				for c in g.get_children():
					if c is FinestraCombattimento:
						await get_tree().create_timer(0.9).timeout
						await foto("striscia%d" % n)
						n += 1
		"nuvole":
			var R = Scenari.costruisci("circo", {"G": "ia", "A": "umano"}, {"seme": 3, "nuvole": 16})
			m.avvia_partita(R, {})
			await get_tree().create_timer(3.0).timeout
			await foto("nuvole1")
			m.gioco.mondo.pitch_dest = 25.0
			m.gioco.mondo.dist_dest = 16.0
			await get_tree().create_timer(2.0).timeout
			await foto("nuvole2")
		"traiettorie":
			var codici = OS.get_environment("CODICI").split(",")
			var lista = []
			for i in codici.size():
				lista.append({"tipo": "nieuport17", "nazione": "francia", "controllo": "umano", "pilota": {"nome": codici[i]}})
			var R = Scenari.schermaglia(lista, {"seme": 1})
			for a in R.S["aerei"]:
				var i = codici.find(a["pilota"])
				var r = 4 + (i / 3) * 5
				a["r"] = r
				a["q"] = 1 + (i % 3) * 4 - r / 2
				a["prua"] = 0
				a["quota"] = 2
			m.avvia_partita(R, {})
			await get_tree().create_timer(1.5).timeout
			var mo = m.gioco.mondo
			mo.vista_alto()
			var cen = Vector3.ZERO
			for a in R.S["aerei"]:
				cen += mo.mondo_da_cella(Vector2i(a["q"], a["r"]))
			var cm = Camera3D.new()
			mo.add_child(cm)
			cm.projection = Camera3D.PROJECTION_ORTHOGONAL
			cm.size = 13.0
			cm.global_position = cen / R.S["aerei"].size() + Vector3(0, 30, 0)
			cm.look_at(cm.global_position - Vector3(0, 1, 0), Vector3(0, 0, -1))
			cm.current = true
			await get_tree().create_timer(1.0).timeout
			m.gioco.modale.visible = false
			for a in R.S["aerei"]:
				var c = a["pilota"]
				mo.anima_manovra(a, {"id": a["id"], "percorso": R.percorso(a, c), "quota_da": 2, "quota_a": 2, "codice": c, "esito": ""}, 2.4, true)
			for k in 8:
				await get_tree().create_timer(0.3).timeout
				for i in codici.size():
					var g: Node3D = mo.nodi[i]["radice"].duplicate()
					mo.effetti.add_child(g)
					g.global_transform = mo.nodi[i]["radice"].global_transform
			await get_tree().create_timer(1.0).timeout
			await foto("traiettorie")
		"prue":
			var lista = []
			for i in 6:
				lista.append({"tipo": ["albatros_d3", "spad7", "fokker_dr1", "camel", "albatros_d5", "nieuport17"][i], "nazione": "germania" if i % 2 == 0 else "francia", "controllo": "ia", "pilota": {"nome": "P%d" % i}})
			var R = Scenari.schermaglia(lista, {"seme": 1})
			for i in 6:
				var a = R.aereo(i)
				a["q"] = 1 + i * 2 - 3
				a["r"] = 6
				a["prua"] = i
			m.avvia_partita(R, {})
			await get_tree().create_timer(1.5).timeout
			m.gioco.mondo.vista_alto()
			m.gioco.mondo.centra_su(m.gioco.mondo.mondo_da_cella(Vector2i(1, 6)), 12.0)
			await get_tree().create_timer(2.5).timeout
			await foto("prue")
		"danni":
			var R = Scenari.costruisci("meute", {"G": "ia", "A": "umano"}, {"seme": 3})
			m.avvia_partita(R, {})
			var g: Gioco = m.gioco
			await get_tree().create_timer(2.0).timeout
			var a = R.aereo(2)
			a["ali"] = 8
			a["fus"] = 6
			a["coda"] = 2
			a["motore"] = 3
			a["fumo"] = true
			a["no_acro"] = true
			a["mitra"][0]["inceppata"] = true
			g._vista_aereo(true)
			g.mostra_aereo(2)
			await get_tree().create_timer(1.5).timeout
			await foto("danni")
			a["fuoco"] = true
			a["fus"] = 0
			g.mostra_aereo(2)
			await get_tree().create_timer(1.5).timeout
			await foto("danni2")
		"replay":
			var R = Scenari.costruisci("immelmann", {"G": "ia", "A": "ia"}, {"seme": 4})
			m.avvia_partita(R, {"veloce": true})
			var g: Gioco = m.gioco
			var t = 0
			while not R.S["finita"] and t < 3000 and g.storia.size() < 3:
				await get_tree().create_timer(0.2).timeout
				t += 1
			await get_tree().create_timer(1.0).timeout
			print("finita ", R.S["finita"], " turni ", g.storia.size())
			for c in g.modale.get_children():
				c.visible = false
			g.set_process(false)
			g.replay()
			for k in 6:
				await get_tree().create_timer(1.7).timeout
				await foto("replay%d" % k)
		"tutorial":
			m.menu._tutorial()
			await get_tree().create_timer(3.0).timeout
			await foto("tutorial1")
	get_tree().quit()

func foto(n: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [dir, n])
	print("foto ", n)
