extends Area2D

# Allows setting the specific target building name right in the Godot inspector
@export var building_name: String = "Langdale Hall" 

func _ready() -> void:
	# Code-based signal fallback: ensures the door's body_entered signal connects 
	# automatically at runtime, preventing potential editor-side signal connection drops.
	if not is_connected("body_entered", _on_body_entered):
		connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Verification step: makes sure the object colliding with the zone is actually the player
	if "Player" in body.name or body.name.begins_with("Player"):
		
		# Validation check: verifies a quest is active and matches this exact campus location
		if Global.active_mission and Global.mission_target_building == building_name:
			var current_scene = get_tree().current_scene
			if current_scene:
				
				# Hierarchy scan: pulls a comprehensive list of all active character nodes currently on the map
				var all_nodes = current_scene.find_children("*", "CharacterBody2D", true, false)
				for child in all_nodes:
					
					# State tracking loop: identifies the specific student companion following the player
					if child.has_method("complete_task") and child.current_state == child.State.FOLLOWING:
						
						# Resolution: executes the NPC's completion sequence and exits the loop cleanly
						child.complete_task()
						return
