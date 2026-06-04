extends Node2D

# Scene Node References: Caches direct links to the active player character and camera nodes
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var boundary_shape: CollisionShape2D = $CameraBoundary/CollisionShape2D

func _ready() -> void:
	# 1. Level Positioning Matrix: Sets the player's vector coordinates if they arrived 
	# from a cross-scene transition tracker, otherwise establishes baseline game-start defaults.
	if Global.use_spawn_position:
		player.global_position = Global.player_spawn_position
		Global.use_spawn_position = false
	else:
		player.global_position = Vector2(0, 0)
		
	# 2. Persistent Quest Evaluation: Checks if an escort objective is active across scene boundaries.
	if Global.active_mission and Global.mission_npc_file_path != "":
		# Runtime Instantiation: Dynamically loads and spawns the companion scene resource data
		var follower_scene = load(Global.mission_npc_file_path)
		var follower = follower_scene.instantiate()
		
		var current_player = get_node_or_null("Player")
		if current_player:
			# State Engine Configuration: Pairs the newly loaded player object to the companion's navigation script, 
			# shifts its state index to FOLLOWING, and retains the targeted map objective data.
			follower.player_in_range = current_player
			follower.current_state = follower.State.FOLLOWING
			follower.target_building_name = Global.mission_target_building
			
			# Spawn Buffer Offset: Offsets the spawn coordinate to prevent asset overlapping or physics collision clipping
			follower.global_position = current_player.global_position + Vector2(-25, 0)
			
			add_child(follower)
			print("🎒 Companion successfully hooked onto the player in this scene!")

# --- SCENE MATRIX TRANSITIONS ---

# Level Handoff (East Boundary): Saves arrival tracking coordinates and executes a deferred scene change to Langdale Hall
func _on_right_trigger_body_entered(body: Node) -> void:
	if body.name == "Player":
		Global.player_spawn_position = Vector2(0, 0) 
		Global.use_spawn_position = true
		get_tree().call_deferred("change_scene_to_file", "res://assets/scenes/Langdale.scn")

# --- CAMERA BOUNDARY MANAGEMENT ---

# Dynamic Viewport Optimization: Captures the geometric limits of the collision boundary 
# and maps those constraints directly onto the player's 2D viewport.
func _on_camera_boundary_body_entered(body: Node) -> void:
	if body.name == "Player":
		var collision_shape = $CameraBoundary/CollisionShape2D
		
		# Structural Math: Queries the global coordinates and rectangular shape dimensions of the bounding box
		var shape_rect = collision_shape.shape.get_rect()
		var global_pos = collision_shape.global_position
		
		# Edge Coordinate Calculations: Establishes pixel-perfect horizontal and vertical outer limits
		var limit_left = global_pos.x + shape_rect.position.x
		var limit_right = limit_left + shape_rect.size.x
		var limit_top = global_pos.y + shape_rect.position.y
		var limit_bottom = limit_top + shape_rect.size.y
		
		# Parameter Assignment: Binds the computed pixel limits directly onto the player camera object
		var active_camera = body.get_node("Camera2D")
		active_camera.limit_left = limit_left
		active_camera.limit_right = limit_right
		active_camera.limit_top = limit_top
		active_camera.limit_bottom = limit_bottom
