extends Node

# --- EXISTING SYSTEM TRACKERS ---
var player_spawn_position: Vector2 = Vector2.ZERO
var use_spawn_position: bool = false
var active_mission: bool = false
var mission_target_building: String = ""
var mission_npc_file_path: String = ""
var mission_npc_hair: Dictionary = {}
var mission_npc_hair_color: Color = Color.WHITE

# --- AI PROCESSING MATRIX (NEW) ---
# Simulates natural language generation (NLG) processing by mapping structural intent
# to randomized semantic variations, laying the pipeline for future direct API integration.
var dialogue_templates: Array[String] = [
	"Hey there! Can you guide me over to %s? I'm running super late!",
	"Excuse me, I'm completely lost on campus. Do you know where %s is?",
	"I missed my morning coffee and have no idea how to get to %s. Help me out?",
	"Hey cat! Think you can lead the way to %s for me real quick?"
]

# Scalable Quest Profiles: Future-proofing the framework to handle diverse behavioral archetypes 
# beyond standard delivery/escort mechanics.
enum QuestType { ESCORT, COURIER, SEARCH_AND_RESCUE }
var current_quest_type: QuestType = QuestType.ESCORT

# --- SYSTEM FUNCTIONS ---

# Natural Language Generation Engine: Simulates an AI rewriting text by programmatically 
# injecting target variables into procedurally selected semantic structures.
func generate_ai_dialogue(target_location: String) -> String:
	randomize()
	if dialogue_templates.size() > 0:
		var chosen_template = dialogue_templates[randi() % dialogue_templates.size()]
		return chosen_template % target_location
	return "Take me to " + target_location + "!"

# Task Type Assigner: Procedurally shifts the mission profile to establish structural variability
func generate_dynamic_quest_type() -> void:
	randomize()
	# Currently constrained to ESCORT for presentation stability; expansion slots ready for alternate logic branches
	var types = [QuestType.ESCORT, QuestType.COURIER, QuestType.SEARCH_AND_RESCUE]
	current_quest_type = types[randi() % types.size()]

func reset_mission() -> void:
	active_mission = false
	mission_target_building = ""
	mission_npc_file_path = ""
	mission_npc_hair = {}
	mission_npc_hair_color = Color.WHITE
