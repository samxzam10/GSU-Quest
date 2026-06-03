extends Node

# Stores a target position string or coordinate across scene swaps
var player_spawn_position: Vector2 = Vector2.ZERO
var use_spawn_position: bool = false
var active_mission: bool = false
var mission_target_building: String = ""

# 🌟 FIX: Track the text path of the file instead of the live CharacterBody2D node
var mission_npc_file_path: String = ""
# Add this handy function to the bottom of your Global.gd script
func reset_mission() -> void:
	active_mission = false
	mission_target_building = ""
	mission_npc_file_path = ""
