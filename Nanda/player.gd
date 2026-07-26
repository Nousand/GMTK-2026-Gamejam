extends CharacterBody2D

# this is the main player script - movement, jumping, swinging the hammer, and taking damage/lives.
# it's a CharacterBody2D so move_and_slide() handles collision with floors/walls for us.
#
# quick note for the group: this player is meant to be portable, meaning any of your scenes should
# be able to drag this in and have it just work. that's why other scripts find the player through
# groups ("player", "hittable") instead of hardcoded node paths - no NodePaths to break if someone
# rearranges the scene tree.

# other scripts (HUD, pickups, ...) can hook into this instead of polling the player every frame
signal lives_changed(lives: int) # fires whenever the life count changes (lose a life or gain one from a heart)

# movement tuning, tweak these in the Inspector to change how the player feels
@export var speed: float = 220.0
@export var acceleration: float = 1800.0 # how fast we ramp up to top speed
@export var friction: float = 1800.0 # how fast we slow to a stop when you let go
@export var jump_velocity: float = -420.0 # negative because up is -y in Godot
@export var gravity: float = 1200.0

# hammer attack tuning
@export var attack_cooldown: float = 0.5 # minimum time between swings
@export var attack_hitbox_offset: float = 24.0 # how far in front of the player the hitbox sits
@export var attack_hitbox_active_time: float = 0.15 # how long the hitbox stays live per swing

# lives tuning
@export var starting_lives: int = 3
@export var invincibility_time: float = 1.0 # can't lose another life until this runs out
@export var hurt_animation_time: float = 0.3 # how long the Hit animation blocks idle/run/jump from taking back over

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var hurt_sound: AudioStreamPlayer2D = $HurtSound

var _attack_cooldown_left: float = 0.0
var _hitbox_time_left: float = 0.0
var _shake_strength: float = 0.0
var _shake_time_left: float = 0.0
var _lives: int
var _invincible_left: float = 0.0
var _sprite_offset_x: float # sprite is nudged off-center to align the art with the frame - mirror it on flip
var _hurt_anim_time_left: float = 0.0

func _ready() -> void:
	# found via groups (not a hardcoded path) so any scene can drop this player in and it just works
	add_to_group("player")
	add_to_group("hittable") # lets enemy attacks find the player via the same take_hit contract
	_lives = starting_lives

	# the sprite isn't perfectly centered on the collision box - it's nudged over on the x-axis
	# in the editor to line up the character art inside its frame (the source images have empty
	# padding around them). we save that offset here so we can mirror it whenever the player
	# turns around. if we don't mirror it, flipping the sprite makes the character drift off to
	# one side while the attack hitbox (which is symmetric) stays lined up correctly, so the two
	# stop matching. see the flip code in _physics_process for where this actually gets used.
	_sprite_offset_x = sprite.position.x

	attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered) # Area2D targets (bell, heart pickups)
	attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered) # physics-body targets (enemies)

func get_lives() -> int:
	return _lives

# heart pickups call this to grant an extra life. lives aren't capped, so this can push us
# above starting_lives - the HUD just adds another heart icon when that happens.
func add_life() -> void:
	_lives += 1
	lives_changed.emit(_lives)

# anything hostile (enemy jump attack, hazards, etc.) calls this to damage us - same contract
# we use on the other side of combat (hammer hitting enemies/the bell), just implemented here
# so the player is a valid "hittable" target too.
func take_hit(_attacker: Node) -> void:
	if _invincible_left > 0.0:
		return # still inside our invincibility window from the last hit, ignore this one

	_lives = max(_lives - 1, 0)
	_invincible_left = invincibility_time
	_hurt_anim_time_left = hurt_animation_time
	sprite.play("Hit")
	hurt_sound.play()
	lives_changed.emit(_lives)
	# no screen shake here on purpose - that's reserved for the bell ringing

var player_dead := false

func _physics_process(delta: float) -> void:
	# stop running after death
	if player_dead:
		return
	
	if _invincible_left > 0.0:
		_invincible_left = max(_invincible_left - delta, 0.0)

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

	# is_action_just_pressed only fires on the exact frame you press the button, so holding
	# attack down doesn't spam swings
	if Input.is_action_just_pressed("attack") and _attack_cooldown_left <= 0.0:
		_attack_cooldown_left = attack_cooldown
		sprite.play("Attack")
		_trigger_attack_hitbox()

	# hitbox only stays live for a short window per swing, then switches back off so it stops
	# registering hits in between swings
	if _hitbox_time_left > 0.0:
		_hitbox_time_left = max(_hitbox_time_left - delta, 0.0)
		if _hitbox_time_left <= 0.0:
			attack_hitbox.monitoring = false

	# hurt animation counts down the same way the hitbox timer does above, just gating the
	# animation instead of a collision shape
	if _hurt_anim_time_left > 0.0:
		_hurt_anim_time_left = max(_hurt_anim_time_left - delta, 0.0)

	move_and_slide()
	
	# Checks if the player touched a spike/damage block
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is TileMapLayer and collider.name == "Traps":
			die()
			break

	# don't let idle/run/jump stomp the attack or hurt animations while they're still playing
	var is_attacking := _attack_cooldown_left > 0.0
	var is_hurt := _hurt_anim_time_left > 0.0
	if not is_attacking and not is_hurt:
		if not is_on_floor():
			sprite.play("Jump")
		elif abs(velocity.x) > 10.0:
			sprite.play("Run")
		else:
			sprite.play("Idle")

	# flip the sprite to actually face the direction we're moving. only touch this when
	# direction != 0 so letting go of the movement keys doesn't snap the character back to
	# some default facing
	if direction != 0:
		sprite.flip_h = direction < 0
		# the sprite's centering offset has to mirror too, or the character art visually
		# drifts off-center when facing left even though the (symmetric) attack hitbox stays
		# lined up correctly. this was a real bug - the hitbox looked wrong on one side but it
		# was actually the sprite that was wrong, not the hitbox math
		sprite.position.x = -_sprite_offset_x if sprite.flip_h else _sprite_offset_x

	# camera shake - just jitters the camera's offset randomly while the timer is still running
	if _shake_time_left > 0.0:
		_shake_time_left -= delta
		camera.offset = Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)
	else:
		camera.offset = Vector2.ZERO
		
	# Die if below 800
	if global_position.y > 2000:
		die()

func die() -> void:
	if player_dead:
		return
	player_dead = true
	
	# Freeze the camera in place
	if camera:
		camera.position_smoothing_enabled = false
		camera.reparent(get_tree().current_scene, true)
		camera.reset_smoothing()
	
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

	# Do a mario like leap death effect
	var start_pos = global_position
	var peak_pos = start_pos + Vector2(0, -80)
	var final_pos = start_pos + Vector2(0, 600)

	var tween = create_tween().set_parallel(true)

	tween.tween_property(self, "global_position:y", peak_pos.y, 0.25)\
		 .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "global_position:y", final_pos.y, 0.6)\
		 .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation_degrees", 360.0, 0.85)
	tween.chain().tween_callback(on_death_complete)

func on_death_complete() -> void:
	get_tree().reload_current_scene()
	
func _trigger_attack_hitbox() -> void:
	# put the hitbox on whichever side we're facing - flip_h true = facing left = negative x
	var facing := -1.0 if sprite.flip_h else 1.0
	attack_hitbox.position.x = attack_hitbox_offset * facing
	attack_hitbox.monitoring = true
	_hitbox_time_left = attack_hitbox_active_time

# Area2D targets (bell, heart pickups) fire area_entered, physics-body targets (enemies) fire
# body_entered - both just forward into the same _try_hit so we don't duplicate the hit logic
func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	_try_hit(area)

func _on_attack_hitbox_body_entered(body: Node) -> void:
	_try_hit(body)

# anything the hammer can hit (bell, enemies, ...) should join the "hittable" group
# and implement take_hit(attacker) - this is the shared contract, not per-target logic
func _try_hit(target: Node) -> void:
	if target == self:
		# the hitbox overlaps the player's own body at close range, so without this check we'd
		# end up hitting (and damaging) ourselves on every swing
		return
	if target.is_in_group("hittable") and target.has_method("take_hit"):
		target.take_hit(self)

# the bell calls this to snap the player back to it once the countdown ends
func teleport_to(target_position: Vector2) -> void:
	global_position = target_position
	velocity = Vector2.ZERO # don't carry momentum through the teleport, would look weird

# call this from anywhere (like the bell getting hit) to give the camera a quick shake
func shake_camera(strength: float = 8.0, duration: float = 0.2) -> void:
	_shake_strength = strength
	_shake_time_left = duration
