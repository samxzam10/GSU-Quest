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
	if body.name == "Player":
		# REPLACE THESE NUMBERS with the exact Transform coordinates you just found!
		Global.player_spawn_position = Vector2(940, -32) 
		
		Global.use_spawn_position = true
		get_tree().call_deferred("change_scene_to_file", "res://assets/scenes/Langdale.tscn")
