extends Node2D

# Grab a direct reference to your player node in the scene tree
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var boundary_shape:  CollisionShape2D = $CameraBoundary/CollisionShape2D


	
	
	
	
	
func _on_right_trigger_body_entered(body: Node) -> void:
	# Safety check: ONLY trigger if the item entering the zone is our actual player
	if body == player:
		GameState.coming_from = "left"
		# Using .call_deferred prevents the engine physics crash!
		get_tree().call_deferred("change_scene_to_file", "res://assets/scenes/Langdale.tscn")


func _on_camera_boundary_body_entered(body: Node) -> void:
	# Make sure it's the player entering the zone
	if body.name == "Player":
		# 1. Get the CollisionShape2D node inside your Area2D
		var collision_shape = $CameraBoundary/CollisionShape2D
		
		# 2. Get the global bounding box details of that shape
		var shape_rect = collision_shape.shape.get_rect()
		var global_pos = collision_shape.global_position
		
		# 3. Calculate the exact Left, Right, Top, and Bottom pixel limits
		var limit_left = global_pos.x + shape_rect.position.x
		var limit_right = limit_left + shape_rect.size.x
		var limit_top = global_pos.y + shape_rect.position.y
		var limit_bottom = limit_top + shape_rect.size.y
		
		# 4. Apply these limits directly to the Player's internal camera
		var camera = body.get_node("Camera2D")
		camera.limit_left = limit_left
		camera.limit_right = limit_right
		camera.limit_top = limit_top
		camera.limit_bottom = limit_bottom
