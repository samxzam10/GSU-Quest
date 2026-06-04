extends Node

# Scene transition management: handles player coordinates when switching between different map levels
var player_spawn_position: Vector2 = Vector2.ZERO
var use_spawn_position: bool = false

# Quest state machine variables: tracks active objective status and destination details globally
var active_mission: bool = false
var mission_target_building: String = ""

# Dynamic spawning data: tracks the file path of the current NPC rather than the instance itself,
# preventing memory leaks and reference errors during scene loads
var mission_npc_file_path: String = ""

# Visual persistence tracking: saves the custom appearance data of the active companion 
# so their sprite sheets match seamlessly when transferring between map scenes
var mission_npc_hair: Dictionary = {}
var mission_npc_hair_color: Color = Color.WHITE

# Lifecycle cleanup: resets all quest-related global data to clear the objective state
# upon mission success or failure
func reset_mission() -> void:
	active_mission = false
	mission_target_building = ""
	mission_npc_file_path = ""
