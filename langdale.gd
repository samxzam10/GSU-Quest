extends Node2D

# Grab a direct reference to your player node inside the Langdale scene
@onready var player: CharacterBody2D = $Player
@onready var camera = $Player/Camera2D

func _ready():
	print("camera node: ", $Player/Camera2D)
	print("camera enabled before: ", $Player/Camera2D.enabled)
	$Player/Camera2D.enabled = true
	print("camera enabled after: ", $Player/Camera2D.enabled)

func _on_left_trigger_body_entered(body: Node) -> void:
	# Safety check: ONLY trigger if the item entering the zone is our actual player
	if body == player:
		# Completely swap this scene file out and load back into the starting world view
		get_tree().call_deferred("change_scene_to_file", "res://assets/scenes/Scene 1.tscn")
 
