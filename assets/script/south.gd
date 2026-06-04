extends Node2D

# Scene Node References: Links the script directly to the active character and camera sub-nodes
@onready var player: CharacterBody2D = $Player
@onready var camera = $Player/Camera2D

func _ready() -> void:
	# 1. Coordinate Syncing: Determines if the player is arriving via a cross-scene marker 
	# and loads their spatial coordinates, otherwise applying a fallback editor coordinate.
	if Global.use_spawn_position:
		player.global_position = Global.player_spawn_position
		Global.use_spawn_position = false
	else:
		player.global_position = Vector2(0, 0)
		
	# 2. State-Based Asset Persistence: Evaluates if an escort quest objective needs to survive a map transition.
	if Global.active_mission and Global.mission_npc_file_path != "":
		# Runtime Asset Extraction: Dynamically references and clones the companion template resource
		var follower_scene = load(Global.mission_npc_file_path)
		var follower = follower_scene.instantiate()
		
		var current_player = get_node_or_null("Player")
		if current_player:
			# Entity Linking: Binds the new scene context to the companion AI script, shifts 
			# behavioral indexes directly to FOLLOWING, and imports original objective targets.
			follower.player_in_range = current_player
			follower.current_state = follower.State.FOLLOWING
			follower.target_building_name = Global.mission_target_building
			
			# Vector Offset Buffer: Displaces spawn coordinates slightly to eliminate asset collision overlaps
			follower.global_position = current_player.global_position + Vector2(-25, 0)
			
			add_child(follower)
			print("🎒 Companion successfully hooked onto the player in this scene!")

# --- SCENE MATRIX TRANSITIONS ---

# Level Handoff (South Boundary): Compiles exit vectors and triggers a deferred scene swap back to Langdale Hall
func _on_bottom_trigger_body_entered(body: Node) -> void:
	if body.name == "Player":
		Global.player_spawn_position = Vector2(940, -32) 
		Global.use_spawn_position = true
		get_tree().call_deferred("change_scene_to_file", "res://assets/scenes/Langdale.scn")

# --- CAMERA VIEWPORT RIGGING ---

# Procedural Camera Bounds: Dissects the structural shape properties of the map bounding box 
# and assigns those literal pixel coordinates directly to the 2D viewport restrictions.
func update_camera_limits() -> void:
	var collision_shape = $Camera_Boundary/CollisionShape2D
	if collision_shape and collision_shape.shape:
		# Spatial Boundary Math: Queries the vector position and size dimensions of the collider rectangle
		var shape_rect = collision_shape.shape.get_rect()
		var global_pos = collision_shape.global_position
		
		# Edge Component Parsing: Establishes absolute horizontal and vertical constraint lines
		var limit_left = global_pos.x + shape_rect.position.x
		var limit_right = limit_left + shape_rect.size.x
		var limit_top = global_pos.y + shape_rect.position.y
		var limit_bottom = limit_top + shape_rect.size.y
		
		# Viewport Injection: Overrides structural limits on the Camera2D node to lock the frame layout
		if camera:
			camera.limit_left = limit_left
			camera.limit_right = limit_right
			camera.limit_top = limit_top
			camera.limit_bottom = limit_bottom
			print("🛡️ Camera boundaries set automatically.")

# Viewport Re-Sync: Forcefully recalculates camera edge math if the physics actor crosses the trigger zone
func _on_camera_boundary_body_entered(body: Node2D) -> void:
	if body == player:
		update_camera_limits()

func _on_body_entered(body: Node2D) -> void:
	pass
