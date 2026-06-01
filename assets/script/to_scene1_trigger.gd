extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		# Tell the global state where the player should emerge inside Scene 1!
		# (Change these numbers to match the side coordinates of Scene 1's entry)
		Global.player_spawn_position = Vector2(400, 150) 
		Global.use_spawn_position = true
		
		# Load Scene 1 map
		get_tree().change_scene_to_file("res://scenes/Scene 1.tscn")
		
