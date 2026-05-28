extends Node2D

# Grab a direct reference to your player node inside the Langdale scene
@onready var player: CharacterBody2D = $Player
@onready var camera = $Player/Camera2D

#func _ready() -> void:
	## Set limits for the Langdale map dimensions
	#camera.limit_left = 0
	#camera.limit_top = 0
	#camera.limit_right = 1500  # Adjust to the pixel width of your Langdale tiles
	#camera.limit_bottom = 800  # Adjust to the pixel height of your Langdale tiles

func _on_left_trigger_body_entered(body: Node) -> void:
	# Safety check: ONLY trigger if the item entering the zone is our actual player
	if body == player:
		# Completely swap this scene file out and load back into the starting world view
		get_tree().call_deferred("change_scene_to_file", "res://assets/scenes/Scene 1.tscn")
 


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
