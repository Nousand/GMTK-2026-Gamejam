extends CharacterBody2D

# the basic enemy pig. it patrols back and forth near where it spawned, and if the player gets
# close enough it jumps at them instead. it also has health and can be knocked out by the
# player's hammer through the same "hittable" group + take_hit(attacker) contract used everywhere
# else (bell, heart pickups, player).

@export var speed: float = 60.0 # patrol/chase walking speed
@export var gravity: float = 1200.0
@export var patrol_distance: float = 80.0 # how far it wanders from its spawn point before turning around
@export var max_health: int = 3
@export var knockback_strength: float = 200.0
@export var hit_stun_time: float = 0.3 # how long it stays stunned (can't move/attack) after taking a hit

# jump attack tuning
@export var detection_range: float = 150.0 # how close the player needs to be before it jumps
@export var attack_cooldown: float = 1.5 # minimum time between jump attacks
@export var attack_lunge_speed: float = 140.0 # horizontal speed of the jump, aimed at the player
@export var attack_jump_velocity: float = -220.0 # vertical impulse of the jump - kept low so it doesn't sail over the player
@export var attack_contact_range: float = 48.0 # how close it needs to get to actually deal damage.
# this is bigger than just the collision box because the sprite is scaled up 2x for visibility and
# the attack pose reaches out further than the body itself - if this is too small the swing will
# look like it connects but nothing happens

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hit_sound: AudioStreamPlayer2D = $HitSound

var _health: int
var _direction: float = 1.0 # -1 = facing/moving left, 1 = facing/moving right
var _spawn_x: float # where it started, patrol wanders around this point
var _hit_stun_left: float = 0.0
var _is_dead: bool = false
var _player: Node2D # cached reference to the player, found once in _ready via the "player" group
var _is_attacking: bool = false # true while it's mid-jump on its attack
var _has_hit_player_this_attack: bool = false # so one jump can only land one hit, not several
var _attack_cooldown_left: float = 0.0

func _ready() -> void:
	add_to_group("hittable") # lets the player's attack hitbox find it via the shared take_hit contract
	_health = max_health
	_spawn_x = global_position.x
	_player = get_tree().get_first_node_in_group("player") # found via group, not a hardcoded path
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if _is_dead:
		return # dead enemies don't do anything, just wait around for the death animation to finish

	velocity.y += gravity * delta

	if _hit_stun_left > 0.0:
		# just got hit, don't do anything else until the stun wears off (also nicely means
		# the knockback velocity set in take_hit doesn't get overwritten immediately after)
		_hit_stun_left = max(_hit_stun_left - delta, 0.0)
	elif _is_attacking:
		_process_attack()
	else:
		_attack_cooldown_left = max(_attack_cooldown_left - delta, 0.0)

		if _should_start_attack():
			_start_attack()
		else:
			# if the player is nearby (just on cooldown from the last jump), keep facing/walking
			# towards them instead of blindly patrolling back toward spawn. without this, landing
			# from a jump could put it outside its patrol range, and it'd immediately turn around
			# and walk away from the player it was just chasing - which looked like it was
			# attacking in the wrong direction
			if _player != null and global_position.distance_to(_player.global_position) <= detection_range:
				var toward: float = sign(_player.global_position.x - global_position.x)
				if toward != 0.0:
					_direction = toward
			else:
				# simple back-and-forth patrol, turn around at the edge of its range or when it hits a wall
				if global_position.x - _spawn_x >= patrol_distance:
					_direction = -1.0
				elif global_position.x - _spawn_x <= -patrol_distance:
					_direction = 1.0
				if is_on_wall():
					_direction *= -1.0

			velocity.x = _direction * speed
			sprite.flip_h = _direction > 0 # sprite art faces left by default, so flip when moving right
			sprite.play("Run")

	move_and_slide()

	# same spike-death check as the player (see player.gd) - touching the "Traps" tile layer
	# is an instant kill, spikes don't discriminate between player and pig
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is TileMapLayer and collider.name == "Traps":
			_die()
			break

# only jump if the player actually exists, we're not still cooling down from the last jump,
# and we're standing on solid ground (don't want it triggering a jump attack mid-air)
func _should_start_attack() -> bool:
	if _player == null or _attack_cooldown_left > 0.0 or not is_on_floor():
		return false
	return global_position.distance_to(_player.global_position) <= detection_range

func _start_attack() -> void:
	_is_attacking = true
	_has_hit_player_this_attack = false
	_attack_cooldown_left = attack_cooldown

	# figure out which way the player actually is right now and launch towards them
	var toward: float = sign(_player.global_position.x - global_position.x)
	if toward == 0.0:
		toward = _direction # directly on top of us somehow, just keep whichever way we were already facing
	_direction = toward

	velocity.x = toward * attack_lunge_speed
	velocity.y = attack_jump_velocity
	sprite.flip_h = _direction > 0 # sprite art faces left by default, so flip when moving right
	sprite.play("Attack")

func _process_attack() -> void:
	# keep facing the player while we're in the air too, in case they move mid-jump - otherwise
	# it'd land facing wherever they were standing when the jump started
	if _player != null:
		var toward: float = sign(_player.global_position.x - global_position.x)
		if toward != 0.0:
			sprite.flip_h = toward > 0 # sprite art faces left by default, so flip when moving right

	# check for contact once per jump - _has_hit_player_this_attack stops a single jump from
	# hitting the player multiple times if we happen to stay in range for a few frames
	if not _has_hit_player_this_attack and _player != null:
		if global_position.distance_to(_player.global_position) <= attack_contact_range:
			_has_hit_player_this_attack = true
			if _player.has_method("take_hit"):
				_player.take_hit(self)

	# once we land, the jump is over, go back to normal patrol/chase behavior
	if is_on_floor():
		_is_attacking = false

# the player's attack hitbox calls this on anything in the "hittable" group
func take_hit(attacker: Node2D) -> void:
	if _is_dead:
		return

	_is_attacking = false # getting hit cancels any jump attack in progress
	_health -= 1
	_hit_stun_left = hit_stun_time
	hit_sound.play()

	# knock it away from whoever hit it
	var away: float = sign(global_position.x - attacker.global_position.x)
	if away == 0.0:
		away = -_direction # fall back to "away from where it's facing" if hit dead-on from directly above

	velocity.x = away * knockback_strength
	velocity.y = -knockback_strength * 0.5 # a bit of upward pop so the knockback actually reads visually

	if _health <= 0:
		_die()
	else:
		sprite.play("Hit")

func _die() -> void:
	_is_dead = true
	remove_from_group("hittable") # can't be hit again while its death animation plays
	collision.set_deferred("disabled", true) # deferred because we might be inside a physics callback right now
	sprite.play("Dead")

func _on_animation_finished() -> void:
	# only queue_free once the Dead animation specifically has finished playing - this signal
	# also fires after Hit/Run finish, so we need to check both conditions
	if _is_dead and sprite.animation == "Dead":
		queue_free()
