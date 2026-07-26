extends Area2D

@export var elevator: AnimatableBody2D
@export var trigger_on_enter: bool = true
@export var trigger_once: bool = true

var start_position: Vector2
var is_activated: bool = false


func _ready() -> void:
	start_position = position
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if elevator and elevator.has_signal("elevator_started"):
		elevator.elevator_started.connect(_on_elevator_started)
	
	print("Button ready - waiting for player")


func _on_body_entered(body: Node) -> void:
	# Ignore TileMapLayer
	if body is TileMapLayer:
		return
	
	if trigger_on_enter and not is_activated:
		activate_button()


func _on_body_exited(body: Node) -> void:
	# Ignore TileMapLayer
	if body is TileMapLayer:
		return
	
	if not trigger_on_enter and not is_activated:
		activate_button()


func activate_button() -> void:
	if is_activated:
		return
	
	if trigger_once:
		is_activated = true
	
	# Make all sprite children invisible
	for child in get_children():
		if child is Sprite2D:
			child.visible = false
	
	# Disable collision
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = true
	
	# Start the elevator
	if elevator and elevator.has_method("start_elevator"):
		elevator.start_elevator()
	else:
		push_error("Cannot start elevator - elevator not set or missing start_elevator function!")


func _on_elevator_started() -> void:
	print("Elevator started!")
