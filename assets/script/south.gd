extends Node2D

# Grab a direct reference to your player node inside the South scene
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	if Global.use_spawn_position:
		# Teleport the player to the side marker we saved from the last scene
		player.global_position = Global.player_spawn_position
		# Reset the flag so future fresh reloads don't break
		Global.use_spawn_position = false
	else:
		# Default position if you run this scene directly from the editor
		player.global_position = Vector2(0, 0)

# --- BOTTOM TRIGGER (Goes back down to Langdale) ---
func _on_bottom_trigger_body_entered(body: Node) -> void:
	# Safety check: ONLY trigger if the item entering the zone is our actual player
	if body == player:
		# Tell Global where the cat should appear at the top side of Langdale's map
		# (Adjust this Vector2 based on where your top road/sidewalk hits the screen edge)
		Global.player_spawn_position = Vector2(0, -320)
		Global.use_spawn_position = true
		
		# Completely swap this scene file out and load back into Langdale
		get_tree().call_deferred("change_scene_to_file", "res://assets/scenes/Langdale.tscn")
