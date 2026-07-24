extends CharacterBody2D

# movement tuning, tweak these to change how the player feels
@export var speed: float = 220.0
@export var acceleration: float = 1800.0
@export var friction: float = 1800.0
@export var jump_velocity: float = -420.0
@export var gravity: float = 1200.0
@export var attack_cooldown: float = 0.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

var _attack_cooldown_left: float = 0.0
var _shake_strength: float = 0.0
var _shake_time_left: float = 0.0

func _physics_process(delta: float) -> void:
	# always fall unless something else overrides velocity.y (like a jump)
	velocity.y += gravity * delta

	# -1 = left, 1 = right, 0 = nothing pressed
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		# ease towards top speed instead of snapping to it straight away, feels less stiff
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		# no input, so slow down to a stop instead of stopping dead
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# only allow jumping when actually standing on something
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	# cooldown counts down every frame, clamped so it never goes negative
	_attack_cooldown_left = max(_attack_cooldown_left - delta, 0.0)

	if Input.is_action_just_pressed("attack") and _attack_cooldown_left <= 0.0:
		_attack_cooldown_left = attack_cooldown
		sprite.play("Attack")

	move_and_slide()

	# don't let idle/run/jump stomp the attack animation while it's still mid-swing
	var is_attacking := _attack_cooldown_left > 0.0
	if not is_attacking:
		if not is_on_floor():
			sprite.play("Jump")
		elif abs(velocity.x) > 10.0:
			sprite.play("Run")
		else:
			sprite.play("Idle")

	# flip the sprite to actually face the direction we're moving
	if direction != 0:
		sprite.flip_h = direction < 0

	# camera shake - just jitters the camera's offset randomly while the timer is still running
	if _shake_time_left > 0.0:
		_shake_time_left -= delta
		camera.offset = Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)
	else:
		camera.offset = Vector2.ZERO

# the bell calls this to snap the player back to it once the countdown ends
func teleport_to(target_position: Vector2) -> void:
	global_position = target_position
	velocity = Vector2.ZERO # don't carry momentum through the teleport, would look weird

# call this from anywhere (like the bell getting hit) to give the camera a quick shake
func shake_camera(strength: float = 8.0, duration: float = 0.2) -> void:
	_shake_strength = strength
	_shake_time_left = duration
