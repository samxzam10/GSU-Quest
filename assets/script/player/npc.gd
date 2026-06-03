extends CharacterBody2D

# --- TASK STATES ---
enum State { WANDERING, TALKING, FOLLOWING }
var current_state: State = State.WANDERING

@export var move_speed: float = 40.0
@export var target_building_name: String = "Langdale" 

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
var hair_color: Color

@onready var body_sprite = $BodySprite
@onready var hair_sprite = $HairSprite
@onready var outfit_sprite = $OutfitSprite
@onready var anim_player = $AnimationPlayer
@onready var wander_timer = $WanderTimer

# Points directly to your child node layout
@onready var question_indicator = $QuestionIndicator

var current_direction: Vector2 = Vector2.ZERO
var is_walking: bool = false

# Tracks if the player is physically standing in the zone
var player_in_range: CharacterBody2D = null 

func _ready() -> void:
	randomize()
	chosen_hair = hair_options[randi() % hair_options.size()]
	hair_color = Color(randf(), randf(), randf(), 1.0)
	
	# Make sure indicator starts hidden
	if question_indicator:
		question_indicator.visible = false
		
	_on_timer_timeout()

func _physics_process(_delta: float) -> void:
	match current_state:
		State.WANDERING:
			if is_walking:
				velocity = current_direction * move_speed
				handle_sprite_flipping(current_direction)
			else:
				velocity = Vector2.ZERO
			move_and_slide()
			
		State.TALKING:
			velocity = Vector2.ZERO 
			if is_walking or anim_player.current_animation != "idle":
				is_walking = false
				play_state_animation("idle")
				
		State.FOLLOWING:
			if player_in_range:
				var distance_to_player = global_position.distance_to(player_in_range.global_position)
				
				if distance_to_player > 45.0:
					var follow_dir = global_position.direction_to(player_in_range.global_position)
					velocity = follow_dir * (move_speed * 1.2) 
					handle_sprite_flipping(follow_dir)
					
					if not is_walking or anim_player.current_animation != "walk":
						is_walking = true
						play_state_animation("walk")
					move_and_slide()
				else:
					velocity = Vector2.ZERO
					if is_walking or anim_player.current_animation != "idle":
						is_walking = false
						play_state_animation("idle")

# --- INPUT HANDLING (FROM IMAGE_1299BA.PNG) ---
func _unhandled_input(event: InputEvent) -> void:
	# If the player presses Enter/Spacebar while standing inside the detection zone
	if event.is_action_pressed("ui_accept") and player_in_range != null:
		interact(player_in_range)

# --- DETECTOR SIGNALS ---
func _on_interaction_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = body # Save player reference dynamically
		
		# Only show indicator if npc is free and player isn't on a mission
		if current_state == State.WANDERING and not Global.active_mission:
			question_indicator.visible = true

func _on_interaction_area_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_in_range = null
		question_indicator.visible = false
		
		if current_state == State.TALKING:
			current_state = State.WANDERING

# --- MISSION INTERACTION LOGIC ---
func interact(player: CharacterBody2D) -> void:
	if current_state == State.WANDERING and not Global.active_mission:
		current_state = State.TALKING
		show_dialogue("Excuse me... please take me to the " + target_building_name + " building!")
		
	elif current_state == State.TALKING:
		current_state = State.FOLLOWING
		question_indicator.visible = false # Hide it during escort
		
		Global.active_mission = true
		Global.mission_target_building = target_building_name
		Global.mission_npc = self
		show_dialogue("Thank you! Lead the way!")

func complete_task() -> void:
	current_state = State.TALKING 
	question_indicator.visible = false
	show_dialogue("We made it to Langdale! Thank you so much! Bye!")
	
	Global.active_mission = false
	Global.mission_target_building = ""
	Global.mission_npc = null
	
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
	
	# Pick random campus spots
	var random_x = randf_range(100.0, 600.0)
	var random_y = randf_range(300.0, 450.0)
	new_npc.global_position = Vector2(random_x, random_y)
	
	get_parent().add_child(new_npc)

func handle_sprite_flipping(direction: Vector2) -> void:
	if direction.x != 0:
		var look_left = direction.x < 0
		body_sprite.flip_h = look_left
		hair_sprite.flip_h = look_left
		outfit_sprite.flip_h = look_left

func play_state_animation(state_name: String) -> void:
	if state_name == "walk":
		body_sprite.hframes = 8
		hair_sprite.hframes = 8
		outfit_sprite.hframes = 8
		body_sprite.texture = load("res://assets/WALKING/base_walk_strip8.png")
		hair_sprite.texture = load(chosen_hair["walk"])
		anim_player.play("walk")
	elif state_name == "idle":
		body_sprite.hframes = 9
		hair_sprite.hframes = 9
		outfit_sprite.hframes = 9
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
	wander_timer.start(randf_range(1.0, 3.0))

func show_dialogue(text: String) -> void:
	print("[NPC UI]: ", text)
