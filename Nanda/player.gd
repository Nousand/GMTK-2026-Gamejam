extends CharacterBody2D

@export var speed: float = 220.0
@export var acceleration: float = 1800.0
@export var friction: float = 1800.0
@export var jump_velocity: float = -420.0
@export var gravity: float = 1200.0
@export var attack_cooldown: float = 0.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _attack_cooldown_left: float = 0.0

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	_attack_cooldown_left = max(_attack_cooldown_left - delta, 0.0)

	if Input.is_action_just_pressed("attack") and _attack_cooldown_left <= 0.0:
		_attack_cooldown_left = attack_cooldown
		sprite.play("Attack")

	move_and_slide()

	var is_attacking := _attack_cooldown_left > 0.0
	if not is_attacking:
		if not is_on_floor():
			sprite.play("Jump")
		elif abs(velocity.x) > 10.0:
			sprite.play("Run")
		else:
			sprite.play("Idle")

	if direction != 0:
		sprite.flip_h = direction < 0

func teleport_to(target_position: Vector2) -> void:
	global_position = target_position
	velocity = Vector2.ZERO
