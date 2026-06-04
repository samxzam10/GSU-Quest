extends CharacterBody2D

@export_category("Stats")
# Balanced Movement Factor: Decreased from 400 to 80 to establish parity with the 
# companion entity's pathing velocities, preventing tracking desynchronization.
@export var speed: int = 65

# Scene Node References: Links script operations to the AnimationTree core layout properties
@onready var animation_tree = $AnimationTree
@onready var playback = animation_tree.get("parameters/playback")

var move_direction: Vector2 = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	# Input Calculation Matrix: Samples 2D keyboard mapping values to evaluate heading direction vectors
	move_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	move_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	
	# Vector Normalization: Cancels out compound diagonal speed multipliers and executes the slide logic
	var motion: Vector2 = move_direction.normalized() * speed
	set_velocity(motion)
	move_and_slide()
	
	# Rendering Pipeline Update: Evaluates the velocity to calculate sprite animations
	update_animation(motion)

func update_animation(motion: Vector2):
	if motion != Vector2.ZERO:
		# BlendSpace Vector Intercepts: Passes active direction components into the AnimationTree blend graphs
		animation_tree.set("parameters/Idle/blend_position", motion)
		animation_tree.set("parameters/Run/blend_position", motion)
		
		# Animation State Machine Request: Signals the playback node to branch into the locomotion state loop
		playback.travel("Run")
	else:
		# Animation State Machine Request: Reverts playback processing back to the idle blending graph
		playback.travel("Idle")

func _on_bottom_trigger_body_entered(body: Node2D) -> void:
	pass
