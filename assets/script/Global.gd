extends Node

# Stores a target position string or coordinate across scene swaps
var player_spawn_position: Vector2 = Vector2.ZERO
var use_spawn_position: bool = false
var active_mission: bool = false
var mission_target_building: String = ""
var mission_npc: CharacterBody2D = null
