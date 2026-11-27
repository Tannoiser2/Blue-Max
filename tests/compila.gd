extends Node
func _ready() -> void:
	for f in DirAccess.get_files_at("res://scripts"):
		if f.ends_with(".gd"):
			var s = load("res://scripts/" + f)
			if s == null:
				print("ERRORE ", f)
	print("compilati")
	get_tree().quit()
