extends Area2D

# Cross-Scene Navigation Trigger: Detects when the player exits the current boundary map
func _on_body_entered(body: Node2D) -> void:
	# Validation: Ensures only the main player entity can trigger the level transfer sequence
	if body.name == "player" or body.name == "Player":
		
		# Spatial Coordinate Archive: Caches the exact entry vector where the player should emerge on the Scene 1 map
		Global.player_spawn_position = Vector2(400, 150)
		Global.use_spawn_position = true
		
		# Scene Context Swap: Defers the map pipeline load to clear the current scene memory safely
		get_tree().change_scene_to_file("res://scenes/Scene 1.scn")
