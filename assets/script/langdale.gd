extends Node2D

# Grab a direct reference to your player node inside the Langdale scene
@onready var player: CharacterBody2D = $Player
@onready var camera = $Player/Camera2D

func _ready() -> void:
	print("--- LANGDALE SCENE LOADED ---")
	print("Global.use_spawn_position status is: ", Global.use_spawn_position)
	print("Global.player_spawn_position value is: ", Global.player_spawn_position)

	if Global.use_spawn_position:
		print("✅ Condition met! Teleporting player to: ", Global.player_spawn_position)
		player.global_position = Global.player_spawn_position
		
		# Force the camera to instantly snap to the player's new teleported position
		if player.has_node("Camera2D"):
			var cam_node = player.get_node("Camera2D")
			cam_node.reset_smoothing()
			cam_node.force_update_scroll()
			print("📷 Camera forced to snap.")
			
		Global.use_spawn_position = false
	else:
		print("❌ Condition failed! Keeping default map setup.")
		
	# Automatically calculate and apply camera bounds if the boundary node exists
	if has_node("Camera_Boundary/CollisionShape2D"):
		update_camera_limits()

func update_camera_limits() -> void:
	var collision_shape = $Camera_Boundary/CollisionShape2D
	if collision_shape and collision_shape.shape:
		var shape_rect = collision_shape.shape.get_rect()
		var global_pos = collision_shape.global_position
		
		# Calculate the exact Left, Right, Top, and Bottom pixel limits
		var limit_left = global_pos.x + shape_rect.position.x
		var limit_right = limit_left + shape_rect.size.x
		var limit_top = global_pos.y + shape_rect.position.y
		var limit_bottom = limit_top + shape_rect.size.y
		
		# Apply these limits directly to the Camera
		if camera:
			camera.limit_left = limit_left
			camera.limit_right = limit_right
			camera.limit_top = limit_top
			camera.limit_bottom = limit_bottom
			print("🛡️ Camera boundaries set automatically.")

func _on_left_trigger_body_entered(body: Node) -> void:
	# Safety check: ONLY trigger if the item entering the zone is our actual player
	if body == player:
		# Tell Global where the cat should appear back on Scene 1's map
		Global.player_spawn_position = Vector2(93, -3)
		Global.use_spawn_position = true
		
		# Completely swap this scene file out and load back into the starting world view
		get_tree().call_deferred("change_scene_to_file", "res://assets/scenes/Scene 1.tscn")

func _on_right_trigger_body_entered(body: Node) -> void:
	# Safety check: ONLY trigger if the item entering the zone is our actual player
	if body == player:
		# Tell Global where the cat should appear on South's map (coming from the left)
		Global.player_spawn_position = Vector2(0, 0)
		Global.use_spawn_position = true
		
		# Completely swap this scene file out and load into the South world view
		get_tree().call_deferred("change_scene_to_file", "res://assets/scenes/South.tscn")

func _on_camera_boundary_body_entered(body: Node) -> void:
	# Fallback if player enters zone manually
	if body == player:
		update_camera_limits()
