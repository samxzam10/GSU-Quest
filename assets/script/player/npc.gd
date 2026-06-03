extends CharacterBody2D

# --- TASK STATES ---
enum State { WANDERING, TALKING, FOLLOWING }
var current_state: State = State.WANDERING

@export var move_speed: float = 40.0
@export var target_building_name: String = "Langdale Hall" 

# Explicitly map walk (8 frames) and idle (9 frames) hair files together
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

var current_direction: Vector2 = Vector2.ZERO
var is_walking: bool = false
var player_in_range: CharacterBody2D = null 

# 🎲 Tracks if this specific student has a mission assignment
var is_quest_giver: bool = false

# --- WANDER TRACKERS ---
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer_counter: float = 0.0
const WANDER_SPEED: float = 30.0

func _ready() -> void:
	# 🌟 FORCE FILE PATH RECOGNITION (Put this first!)
	if scene_file_path == "":
		scene_file_path = "res://assets/scenes/npc.tscn"
	randomize()
	
	# 1. Choose Random Appearance Assets
	chosen_hair = hair_options[randi() % hair_options.size()]
	
	hair_color = Color(randf(), randf(), randf(), 1.0)
	
	# Apply hair color tint immediately
	if hair_sprite:
		hair_sprite.modulate = hair_color
	
	# 2. Choose a random destination campus building
	var landmarks = ["Langdale Hall", "Classroom South"]
	target_building_name = landmarks[randi() % landmarks.size()]
	
	# 3. 🎲 RANDOM QUEST DISTRIBUTION:
	if randf() < 0.3:
		is_quest_giver = true
	else:
		is_quest_giver = false
	
	# 🌟 EXCLAMATION MARK POPUP: Show it instantly ONLY if they have a quest!
	if question_indicator:
		question_indicator.visible = is_quest_giver
	else:
		print("⚠️ ERROR: Could not find a child node named QuestionIndicator!")
		
	# Boot the initial visual layout and timer
	_on_timer_timeout()

func _physics_process(delta: float) -> void:
	match current_state:
		State.WANDERING:
			# 🏃‍♂️ CAMPUS WANDER LOGIC:
			wander_timer_counter -= delta
			if wander_timer_counter <= 0:
				# Pick a random direction (Left, Right, Up, Down, or Stand Still)
				var angles = [0, 90, 180, 270, -1]
				var chosen_angle = angles[randi() % angles.size()]
				
				if chosen_angle == -1:
					wander_direction = Vector2.ZERO 
				else:
					wander_direction = Vector2.UP.rotated(deg_to_rad(chosen_angle))
				
				# Hold this direction for a random time between 1 and 3 seconds
				wander_timer_counter = randf_range(1.0, 3.0)
			
			velocity = wander_direction * WANDER_SPEED
			handle_sprite_flipping(velocity)
			
			if velocity != Vector2.ZERO:
				play_state_animation("walk")
			else:
				play_state_animation("idle")
				
			move_and_slide()
			
		State.TALKING:
			# NPC stands completely still while asking for help
			velocity = Vector2.ZERO
			play_state_animation("idle")
			move_and_slide()
			
		State.FOLLOWING:
			# 🐱 ATTACH TO CAT LOGIC:
			if player_in_range:
				var direction = global_position.direction_to(player_in_range.global_position)
				var distance = global_position.distance_to(player_in_range.global_position)
				handle_sprite_flipping(direction)
				
				# Only walk if the cat is more than 30 pixels away (stops clipping)
				if distance > 30.0:
					velocity = direction * 60.0 # Speed up slightly to keep pace with the cat
					play_state_animation("walk")
				else:
					velocity = Vector2.ZERO
					play_state_animation("idle")
			else:
				velocity = Vector2.ZERO
				play_state_animation("idle")
				
			move_and_slide()

# --- INPUT HANDLING ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and player_in_range != null and is_quest_giver:
		interact(player_in_range)

# --- DETECTOR SIGNALS ---
func _on_interaction_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = body
		print("📢 Player entered NPC detection radius! Is Quest Giver: ", is_quest_giver)
		
		# 🐱 AUTO-INTERACT: Talk and follow instantly on contact!
		if is_quest_giver and current_state == State.WANDERING and not Global.active_mission:
			# 1. Stop wandering and show the dialogue bubble
			current_state = State.TALKING
			show_dialogue("Excuse me... please take me to " + target_building_name + "!")
			
			# 2. Wait 2.5 seconds so the player can actually read the text
			await get_tree().create_timer(2.5).timeout
			
			# 3. Safety check to make sure the cat didn't sprint away during the chat
			if player_in_range != null:
				current_state = State.FOLLOWING
				if question_indicator:
					question_indicator.visible = false 
				
				# 4. Save tracking data to our global variables
				Global.active_mission = true
				Global.mission_target_building = target_building_name
				Global.mission_npc_file_path = self.scene_file_path 
				
				show_dialogue("Lead the way!")

func _on_interaction_area_body_exited(body: Node) -> void:
	if body.name == "Player":
		print("🚶 Player walked away from NPC.")
		player_in_range = null
		
		# Put the marker back up if they walked away without accepting the escort
		if is_quest_giver and current_state == State.WANDERING:
			if question_indicator:
				question_indicator.visible = true
		
		if current_state == State.TALKING:
			current_state = State.WANDERING

# --- MISSION INTERACTION LOGIC ---
func interact(player_node: CharacterBody2D) -> void:
	if current_state == State.WANDERING and not Global.active_mission:
		current_state = State.FOLLOWING
		
		if question_indicator:
			question_indicator.visible = false 
		
		Global.active_mission = true
		Global.mission_target_building = target_building_name
		Global.mission_npc_file_path = self.scene_file_path
		
		show_dialogue("Excuse me! Can you please take me to " + target_building_name + "? Lead the way!")

func complete_task() -> void:
	current_state = State.TALKING 
	if question_indicator:
		question_indicator.visible = false
	show_dialogue("We made it! Thank you so much! Bye!")
	
	Global.active_mission = false
	Global.mission_target_building = ""
	Global.mission_npc_file_path = ""
	
	# Smoothly fade out and respawn
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.5)
	tween.tween_callback(func():
		respawn_somewhere_else()
		queue_free()
	)

func respawn_somewhere_else() -> void:
	var npc_scene = load(self.scene_file_path) 
	var new_npc = npc_scene.instantiate()
	
	var random_x = randf_range(150.0, 550.0)
	var random_y = randf_range(200.0, 400.0)
	new_npc.global_position = Vector2(random_x, random_y)
	
	get_parent().add_child(new_npc)

func handle_sprite_flipping(direction: Vector2) -> void:
	if direction.x != 0:
		var look_left = direction.x < 0
		body_sprite.flip_h = look_left
		hair_sprite.flip_h = look_left
		if outfit_sprite:
			outfit_sprite.flip_h = look_left

func play_state_animation(state_name: String) -> void:
	if state_name == "walk":
		body_sprite.hframes = 8
		hair_sprite.hframes = 8
		if outfit_sprite: outfit_sprite.hframes = 8
		body_sprite.texture = load("res://assets/WALKING/base_walk_strip8.png")
		hair_sprite.texture = load(chosen_hair["walk"])
		anim_player.play("walk")
	elif state_name == "idle":
		body_sprite.hframes = 9
		hair_sprite.hframes = 9
		if outfit_sprite: outfit_sprite.hframes = 9
		body_sprite.texture = load("res://assets/IDLE/base_idle_strip9.png")
		hair_sprite.texture = load(chosen_hair["idle"])
		anim_player.play("idle")
	hair_sprite.modulate = hair_color

func _on_timer_timeout() -> void:
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
	print("[NPC UI]: ", text) 
	
	if has_node("DialogueLabel"):
		var label = $DialogueLabel
		
		# 🎯 1. Make the font tiny and balanced
		label.add_theme_font_size_override("font_size", 6)
		
		# 📦 2. Force smart auto-wrap so lines stack instead of running offscreen
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		# 🗃️ 3. Set custom bounds to keep it grouped tightly over their heads
		label.custom_minimum_size = Vector2(70, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		label.text = text
		label.visible = true
		
		# Leaves the text visible on screen for 2.5 seconds
		await get_tree().create_timer(2.5).timeout
		
		if is_instance_valid(label):
			label.visible = false
