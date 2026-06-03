extends Node2D

# Grab a direct reference to your player node in the scene tree
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var boundary_shape:  CollisionShape2D = $CameraBoundary/CollisionShape2D

func _ready() -> void:
	if Global.use_spawn_position:
		# Teleport the player to the side marker we saved from the last scene
		player.global_position = Global.player_spawn_position
		# Reset the flag so future fresh reloads don't break
		Global.use_spawn_position = false
	else:
		# Fresh game start position!
		player.global_position = Vector2(0, 0)
	# Paste this at the absolute bottom of func _ready() inside your map scripts:
	if Global.active_mission and Global.mission_npc_file_path != "":
		# 1. Load the NPC template file back into active memory
		var follower_scene = load(Global.mission_npc_file_path)
		var follower = follower_scene.instantiate()
		
		# 2. Tell the new instance it is already following the player cat
		follower.current_state = follower.State.FOLLOWING
		follower.player_in_range = player # Pairs it to this current map's player node
		follower.target_building_name = Global.mission_target_building
		
		# 3. Position the follower right next to where your cat spawns
		follower.global_position = player.global_position + Vector2(-30, 0)
		
		# 4. Spawn them into the live map world
		add_child(follower)
		print("🎒 Companion successfully moved through the door into the new scene!")
	
	
	
	
func _on_right_trigger_body_entered(body: Node) -> void:
	# 🐱 Secure the door so only the player can trip it
	if body.name == "Player":
		Global.player_spawn_position = Vector2(0,0) # Open space on Langdale
		Global.use_spawn_position = true
		
		# Move to Langdale
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
		
