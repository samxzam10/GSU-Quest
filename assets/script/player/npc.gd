extends CharacterBody2D

@export var move_speed: float = 40.0

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

var current_direction: Vector2 = Vector2.ZERO
var is_walking: bool = false

func _ready() -> void:
	randomize()
	
	# Pick a style bundle once for this specific student
	chosen_hair = hair_options[randi() % hair_options.size()]
	
	# Generate a random color tint for their hair style
	hair_color = Color(randf(), randf(), randf(), 1.0)
	
	# Kick off the movement loops immediately
	_on_timer_timeout()

func _physics_process(_delta: float) -> void:
	if is_walking:
		velocity = current_direction * move_speed
		
		# Flip sprites left or right depending on the movement vector
		if current_direction.x != 0:
			var look_left = current_direction.x < 0
			body_sprite.flip_h = look_left
			hair_sprite.flip_h = look_left
			outfit_sprite.flip_h = look_left
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()

# Swaps textures and sets Hframes correctly right before playing the animation tracks
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
		
	# Keep the randomized color tint locked onto the hair layer
	hair_sprite.modulate = hair_color

# Connected to your WanderTimer timeout signal!
func _on_timer_timeout() -> void:
	# Pick a random direction: Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, or Vector2.ZERO (idle)
	var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2.ZERO]
	current_direction = directions[randi() % directions.size()]
	
	# Update tracking variables so _physics_process moves the character
	if current_direction == Vector2.ZERO:
		is_walking = false
		play_state_animation("idle")
	else:
		is_walking = true
		play_state_animation("walk")
		
	# Restart the timer for a random interval (between 1 and 3 seconds)
	wander_timer.start(randf_range(1.0, 3.0))
