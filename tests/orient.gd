extends Node3D
func _ready() -> void:
	var cam = Camera3D.new(); add_child(cam)
	cam.look_at_from_position(Vector3(0, 4, 0.001), Vector3.ZERO, Vector3(0,0,-1))
	var l = DirectionalLight3D.new(); l.rotation_degrees = Vector3(-60, 0, 0); add_child(l)
	var x = -1.5
	for t in ["fokker_dr1", "spad7", "bristol", "se5a", "spad13", "nieuport28", "halberstadt"]:
		var m = load("res://assets/modelli/%s.glb" % t).instantiate()
		add_child(m); m.position = Vector3(x, 0, 0); m.scale = Vector3.ONE * 0.4; x += 0.5
		var aabb = AABB()
		print(t, " ", _aabb(m))
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/orient.png")
	get_tree().quit()
func _aabb(n: Node) -> AABB:
	var b = AABB(); var first = true
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var bb = c.global_transform * c.get_aabb()
		if first: b = bb; first = false
		else: b = b.merge(bb)
	return b
