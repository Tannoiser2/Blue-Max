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
			g.mondo.anteprima(a, "3A2", 0)
			await get_tree().create_timer(0.5).timeout
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
