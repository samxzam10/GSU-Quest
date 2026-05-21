extends Node2D

# Grab a direct reference to your player node in the scene tree
@onready var player: CharacterBody2D = $Player

func _on_right_trigger_body_entered(body: Node) -> void:
	# Safety check: ONLY trigger if the item entering the zone is our actual player
	if body == player:
		GameState.coming_from = "left"
		# Using .call_deferred prevents the engine physics crash!
		get_tree().call_deferred("change_scene_to_file", "res://assets/scenes/Langdale.tscn")
