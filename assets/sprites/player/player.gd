extends CharacterBody2D

@export_category("Stats")
@export var speed: int = 400

# Get references to your nodes
@onready var animation_tree = $AnimationTree
@onready var playback = animation_tree.get("parameters/playback")

var move_direction: Vector2 = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	# Your existing movement logic
	move_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	move_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	
	var motion: Vector2 = move_direction.normalized() * speed
	set_velocity(motion)
	move_and_slide()
	
	# Update animations
	update_animation(motion)

func update_animation(motion: Vector2):
	if motion != Vector2.ZERO:
		# Update the blend positions for your 2D BlendSpaces
		animation_tree.set("parameters/Idle/blend_position", motion)
		animation_tree.set("parameters/Run/blend_position", motion)
		
		# Tell the state machine to switch to the Run state
		playback.travel("Run")
	else:
		# Tell the state machine to switch to the Idle state
		playback.travel("Idle")
