extends CharacterBody2D

# Finite State Machine: Manages behavioral modes for campus NPCs
enum State { WANDERING, TALKING, FOLLOWING }
var current_state: State = State.WANDERING

@export var move_speed: float = 40.0
@export var target_building_name: String = "Langdale Hall" 

# Asset Dictionary Array: Coordinates matching frame counts for walk (8-frame) and idle (9-frame) texture strips
var hair_options = [
	{"walk": "res://assets/WALKING/longhair_walk_strip8.png", "idle": "res://assets/IDLE/longhair_idle_strip9.png"},
	{"walk": "res://assets/WALKING/bowlhair_walk_strip8.png", "idle": "res://assets/IDLE/bowlhair_idle_strip9.png"},
	{"walk": "res://assets/WALKING/shorthair_walk_strip8.png", "idle": "res://assets/IDLE/shorthair_idle_strip9.png"},
	{"walk": "res://assets/WALKING/spikeyhair_walk_strip8.png", "idle": "res://assets/IDLE/spikeyhair_idle_strip9.png"},
	{"walk": "res://assets/WALKING/mophair_walk_strip8.png", "idle": "res://assets/IDLE/mophair_idle_strip9.png"},
	{"walk": "res://assets/WALKING/curlyhair_walk_strip8.png", "idle": "res://assets/IDLE/curlyhair_idle_strip9.png"}
]

var chosen_hair: Dictionary
var chosen_outfit: Dictionary
var hair_color: Color

@onready var body_sprite = $BodySprite
@onready var hair_sprite = $HairSprite
@onready var outfit_sprite = $OutfitSprite
@onready var anim_player = $AnimationPlayer
@onready var wander_timer = $WanderTimer
@onready var question_indicator = $QuestionIndicator
@onready var dialogue_label = $DialogueLabel

var current_direction: Vector2 = Vector2.ZERO
var is_walking: bool = false
var player_in_range: CharacterBody2D = null 

# Quest Generation Variable: Flags if this specific instance spawns with an active delivery objective
var is_quest_giver: bool = false

# Movement Parameters: Tracks step directions and time intervals during automated wandering
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer_counter: float = 0.0
const WANDER_SPEED: float = 30.0

func _ready() -> void:
	if scene_file_path == "":
		scene_file_path = "res://assets/scenes/npc.tscn"
	randomize()
	
	# Scene Restoration Check: Ensures that if an NPC is cloned into a new map during an active escort, 
	# they retrieve their exact original style properties from the Global singleton instead of rerolling.
	if Global.active_mission and current_state == State.FOLLOWING:
		chosen_hair = Global.mission_npc_hair
		hair_color = Global.mission_npc_hair_color
		is_quest_giver = false 
		
		if question_indicator:
			question_indicator.visible = false
	else:
		# Procedural Variation: Randomizes the aesthetic features and destination criteria for ambient campus students
		if hair_options.size() > 0:
			chosen_hair = hair_options[randi() % hair_options.size()]
		hair_color = Color(randf(), randf(), randf(), 1.0)
		
		var landmarks = ["Langdale Hall", "Classroom South"]
		target_building_name = landmarks[randi() % landmarks.size()]
		
		# Probability Weighting: Assigns a 30% baseline chance for a spawned NPC to become a quest objective
		if randf() < 0.3:
			is_quest_giver = true
		else:
			is_quest_giver = false
			
		if question_indicator:
			question_indicator.visible = is_quest_giver

	if hair_sprite:
		hair_sprite.modulate = hair_color
		
	if has_node("DialogueLabel"):
		$DialogueLabel.visible = false
		
	_on_timer_timeout()

func _physics_process(delta: float) -> void:
	# Behavior Tree Processing: Drives physical movement updates based on the current state machine value
	match current_state:
		State.WANDERING:
			wander_timer_counter -= delta
			if wander_timer_counter <= 0:
				var angles = [0, 90, 180, 270, -1]
				var chosen_angle = angles[randi() % angles.size()]
				
				if chosen_angle == -1:
					wander_direction = Vector2.ZERO 
				else:
					wander_direction = Vector2.UP.rotated(deg_to_rad(chosen_angle))
				
				wander_timer_counter = randf_range(1.0, 3.0)
			
			velocity = wander_direction * WANDER_SPEED
			handle_sprite_flipping(velocity)
			
			if velocity != Vector2.ZERO:
				play_state_animation("walk")
			else:
				play_state_animation("idle")
				
			move_and_slide()
			
		State.TALKING:
			velocity = Vector2.ZERO
			play_state_animation("idle")
			move_and_slide()
			
		State.FOLLOWING:
			if player_in_range:
				# Vector Pathing: Calculates the distance and steering angle towards the player character
				var direction = global_position.direction_to(player_in_range.global_position)
				var distance = global_position.distance_to(player_in_range.global_position)
				handle_sprite_flipping(direction)
				
				# Deadzone Buffer: Maintains a follow-distance cushion so the NPC doesn't overlap the player
				if distance > 30.0:
					velocity = direction * 60.0 
					play_state_animation("walk")
				else:
					velocity = Vector2.ZERO
					play_state_animation("idle")
			else:
				var new_player = get_parent().get_node_or_null("Player")
				if new_player:
					player_in_range = new_player
				else:
					velocity = Vector2.ZERO
					play_state_animation("idle")
				
			move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and player_in_range != null and is_quest_giver:
		interact(player_in_range)

# --- DETECTION AND REGISTRATION SIGNALS ---

func _on_interaction_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = body as CharacterBody2D
		
		# Proximity Handoff: Auto-triggers dialogue and populates global memory when a player approaches a quest-giver
		if is_quest_giver and current_state == State.WANDERING and not Global.active_mission:
			current_state = State.TALKING
			
			Global.active_mission = true
			Global.mission_target_building = target_building_name
			Global.mission_npc_file_path = self.scene_file_path 
			Global.mission_npc_hair = chosen_hair
			Global.mission_npc_hair_color = hair_color
			
			var ai_generated_text: String = Global.generate_ai_dialogue(target_building_name)
			print("AI Output Log: " + ai_generated_text)
			show_dialogue(ai_generated_text)
			
			await get_tree().create_timer(2.5).timeout
			
			if player_in_range == null:
				player_in_range = body as CharacterBody2D
				
			current_state = State.FOLLOWING
			if question_indicator:
				question_indicator.visible = false 
				
			if has_node("DialogueLabel"):
				$DialogueLabel.visible = false

func _on_interaction_area_body_exited(body: Node) -> void:
	if body.name == "Player":
		# Out-Of-Bounds Recovery: Resets behavior to standard wander parameters if the player leaves mid-conversation
		if current_state == State.WANDERING or current_state == State.TALKING:
			player_in_range = null
			if is_quest_giver and question_indicator:
				question_indicator.visible = true
			current_state = State.WANDERING
			if has_node("DialogueLabel"):
				$DialogueLabel.visible = false

# --- MISSION LOGIC EXECUTION ---

func interact(player_node: CharacterBody2D) -> void:
	# Input Event Trigger: Forces escort enrollment manually if proximity routines are bypassed
	if current_state == State.WANDERING and not Global.active_mission:
		current_state = State.FOLLOWING
		player_node = player_node
		
		if question_indicator:
			question_indicator.visible = false 
		
		Global.active_mission = true
		Global.mission_target_building = target_building_name
		Global.mission_npc_file_path = self.scene_file_path
		Global.mission_npc_hair = chosen_hair
		Global.mission_npc_hair_color = hair_color
		
		var ai_generated_text: String = Global.generate_ai_dialogue(target_building_name)
		print("AI Output Log: " + ai_generated_text)
		show_dialogue(ai_generated_text)

func complete_task() -> void:
	# Quest Resolution: Freezes entity processing and clears out global tracker states upon arrival at the target building
	current_state = State.TALKING 
	if question_indicator:
		question_indicator.visible = false
		
	print("Thank you! Mission Complete!")
	show_dialogue("Thank you!\nMission Complete!")
	
	Global.reset_mission()
	player_in_range = null
	
	# Tween Interpolation: Creates a smooth 1.8-second opacity fade-out animation prior to clearing memory allocation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.8)
	tween.tween_callback(func():
		if has_node("DialogueLabel"):
			$DialogueLabel.visible = false
		respawn_somewhere_else()
		queue_free()
	)

func respawn_somewhere_else() -> void:
	# Level Balancer: Instantiates a fresh replacement civilian elsewhere on campus to maintain population density
	var npc_scene = load(self.scene_file_path) 
	var new_npc = npc_scene.instantiate()
	
	var random_x = randf_range(150.0, 550.0)
	var random_y = randf_range(200.0, 400.0)
	new_npc.global_position = Vector2(random_x, random_y)
	
	get_parent().add_child(new_npc)

# --- RENDERING AND ANIMATION ROUTINES ---

func handle_sprite_flipping(direction: Vector2) -> void:
	# Horizontal Reflection: Mirrors sprite orientation parameters based on the velocity vector sign
	if direction.x != 0:
		var look_left = direction.x < 0
		body_sprite.flip_h = look_left
		hair_sprite.flip_h = look_left
		if outfit_sprite:
			outfit_sprite.flip_h = look_left

func play_state_animation(state_name: String) -> void:
	# Frame Partitioning: Dynamically alters texture source paths, scale parameters, and hframe counts
	# depending on whether the current motion requires an 8-frame walk or 9-frame idle loops.
	if state_name == "walk" and body_sprite and hair_sprite:
		body_sprite.hframes = 8
		hair_sprite.hframes = 8
		if outfit_sprite: outfit_sprite.hframes = 8
		body_sprite.texture = load("res://assets/WALKING/base_walk_strip8.png")
		hair_sprite.texture = load(chosen_hair["walk"])
		anim_player.play("walk")
	elif state_name == "idle" and body_sprite and hair_sprite:
		body_sprite.hframes = 9
		hair_sprite.hframes = 9
		if outfit_sprite: outfit_sprite.hframes = 9
		body_sprite.texture = load("res://assets/IDLE/base_idle_strip9.png")
		hair_sprite.texture = load(chosen_hair["idle"])
		anim_player.play("idle")
	if hair_sprite:
		hair_sprite.modulate = hair_color

func _on_timer_timeout() -> void:
	# Random Navigation Handler: Injects behavioral variance by updating direction choices at intermittent clock intervals
	if current_state == State.WANDERING:
		var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2.ZERO]
		current_direction = directions[randi() % directions.size()]
		if current_direction == Vector2.ZERO:
			is_walking = false
			play_state_animation("idle")
		else:
			is_walking = true
			play_state_animation("walk")
	if wander_timer:
		wander_timer.start(randf_range(1.0, 3.0))

func show_dialogue(text: String) -> void:
	# Dynamic Text Rendering: Programs UI layout controls and pushes formatting overrides directly to the overhead Label
	if has_node("DialogueLabel"):
		var label = $DialogueLabel
		label.add_theme_font_size_override("font_size", 6)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(70, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		label.text = text
		label.visible = true
