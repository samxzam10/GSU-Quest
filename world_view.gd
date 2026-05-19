extends Node2D

@onready var camera = $Player/Camera2D
@onready var player = $Player

var screen_width: float = 1100.0
var screen_height: float = 700.0  # adjust to your window height

func _on_right_trigger_body_entered(body: Node) -> void:
	if body == player:
		camera.global_position.x += screen_width
		player.global_position.x += 60.0

func _on_left_trigger_body_entered(body: Node) -> void:
	if body == player:
		camera.global_position.x -= screen_width
		player.global_position.x -= 60.0

func _on_bottom_trigger_body_entered(body: Node) -> void:
	if body == player:
		camera.global_position.y += screen_height
		player.global_position.y += 60.0

func _on_top_trigger_body_entered(body: Node) -> void:
	if body == player:
		camera.global_position.y -= screen_height
		player.global_position.y -= 60.0
