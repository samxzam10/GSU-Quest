extends Area2D

# In the Inspector for the Langdale doors, type: Langdale Hall
# In the Inspector for the South doors, type: Classroom South
@export var building_name: String = "Langdale Hall"

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		# Check if you are actively escorting an NPC to THIS building
		if Global.active_mission and Global.mission_target_building == building_name:
			if is_instance_valid(Global.mission_npc):
				Global.mission_npc.complete_task()
