extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		# Tell the global state where the player should emerge inside Langdale!
		# (Change these numbers to match the side coordinates of Langdale's entry)
		Global.player_spawn_position = Vector2(-200, 50) 
		Global.use_spawn_position = true
		
		# Load the Langdale map
		get_tree().change_scene_to_file("res://scenes/Langdale.tscn")
