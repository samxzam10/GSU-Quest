extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera = $Player/Camera2D

func _ready() -> void:
	# 1. Level Positioning: Sets the player's physical coordinates if they arrived 
	# from another scene, then resets the tracking flag.
	if Global.use_spawn_position:
		player.global_position = Global.player_spawn_position
		Global.use_spawn_position = false
		
	# 2. Viewport Initialization: Dynamically locks the camera window to the map boundaries.
	update_camera_limits()
	
	# 3. Persistent Quest Persistence: Checks if an escort mission is active across scene loads.
	if Global.active_mission and Global.mission_npc_file_path != "":
		# Runtime Instantiation: Dynamically loads and instantiates the companion scene template
		var follower_scene = load(Global.mission_npc_file_path)
		var follower = follower_scene.instantiate()
		
		var current_player = get_node_or_null("Player")
		if current_player:
			# State Initialization: Connects the new map's player instance to the companion's AI logic,
			# shifts their state machine directly to FOLLOWING, and copies over the original objective data.
			follower.player_in_range = current_player
			follower.current_state = follower.State.FOLLOWING
			follower.target_building_name = Global.mission_target_building
			
			# Collision Avoidance: Offsets the spawn location slightly to avoid clipping into the player's physics capsule
			follower.global_position = current_player.global_position + Vector2(-25, 0)
			
			add_child(follower)
			print("🎒 Companion successfully hooked onto the player in this scene!")

# Procedural Camera Bounds: Automatically queries the collision shape of the map bounding box
# and maps its edges directly to the 2D camera viewport limits.
func update_camera_limits() -> void:
	var collision_shape = $Camera_Boundary/CollisionShape2D
	if collision_shape and collision_shape.shape:
		var shape_rect = collision_shape.shape.get_rect()
		var global_pos = collision_shape.global_position
		
		var limit_left = global_pos.x + shape_rect.position.x
		var limit_right = limit_left + shape_rect.size.x
		var limit_top = global_pos.y + shape_rect.position.y
		var limit_bottom = limit_top + shape_rect.size.y
		
		if camera:
			camera.limit_left = limit_left
			camera.limit_right = limit_right
			camera.limit_top = limit_top
			camera.limit_bottom = limit_bottom

# --- SCENE MATRIX TRANSITIONS ---

# Level Handoff (East Boundary): Archives coordinates and changes scene context to Classroom South
func _on_right_trigger_body_entered(body: Node) -> void:
	if body.name == "Player":
		Global.player_spawn_position = Vector2(0, 0) 
		Global.use_spawn_position = true
		get_tree().call_deferred("change_scene_to_file", "res://assets/scenes/South.scn")

# Level Handoff (West Boundary): Archives coordinates and changes scene context back to Scene 1
func _on_left_trigger_body_entered(body: Node) -> void:
	if body.name == "Player":
		Global.player_spawn_position = Vector2(93, 0)
		Global.use_spawn_position = true
		get_tree().call_deferred("change_scene_to_file", "res://assets/scenes/Scene 1.scn")

# Safety Listener: Re-syncs the viewport geometry boundaries if the player forces a sudden re-entry
func _on_camera_boundary_body_entered(body: Node2D) -> void:
	if body == player:
		update_camera_limits()

func _on_body_entered(body: Node2D) -> void:
	pass
