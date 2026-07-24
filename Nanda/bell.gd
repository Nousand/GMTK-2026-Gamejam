extends Area2D

# other scripts (obstacles, UI, whatever) can hook into these instead of polling the bell every frame
signal rung(duration: float) # fires the moment the bell gets hit and the countdown starts
signal countdown_ended() # fires the moment the countdown finishes and the player's back

@export var countdown_time: float = 5.0
@export var attack_action: String = "attack" # which input action counts as "hitting" the bell

# this is basically the whole state machine - true while the countdown is running.
# anything that needs to know if the bell is "live" can just check this directly.
var is_timer_active: bool = false

var _player_in_range: CharacterBody2D = null # whoever is standing close enough to ring it
var _rung_player: CharacterBody2D = null # whoever actually rang it, so we know who to teleport back
var _aura_tween: Tween = null # keeping a handle on this so we can cancel the pulse loop later

@onready var _timer: Timer = $CountdownTimer
@onready var _ring_sound: AudioStreamPlayer2D = $RingSound
@onready var _swing: AnimationPlayer = $SwingAnimation
@onready var _aura: Sprite2D = $Aura

func _ready() -> void:
	add_to_group("bell") # lets UI (or anything else) find the bell without a hardcoded scene path
	_timer.wait_time = countdown_time
	_timer.one_shot = true # we restart it manually each ring, don't want it auto-looping
	_timer.timeout.connect(_on_timer_timeout)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# only ring if someone's actually in range, it's not already going, and they just pressed attack
	if _player_in_range and not is_timer_active and Input.is_action_just_pressed(attack_action):
		ring(_player_in_range)

func ring(player: CharacterBody2D) -> void:
	if is_timer_active:
		return # already rung, ignore extra hits until it resets

	is_timer_active = true
	_rung_player = player
	_timer.start()
	_ring_sound.play()
	_swing.play("swing")
	player.shake_camera()

	# fade the purple glow in, then keep it pulsing like a heartbeat for as long as it's active
	_aura_tween = create_tween()
	_aura_tween.set_loops()
	_aura_tween.tween_property(_aura, "modulate:a", 1.0, 0.3)
	_aura_tween.tween_property(_aura, "modulate:a", 0.4, 0.3)

	rung.emit(countdown_time)

# lets the UI show the actual countdown number without reaching into the Timer directly
func get_time_left() -> float:
	return _timer.time_left

func _on_timer_timeout() -> void:
	is_timer_active = false
	if _rung_player:
		_rung_player.teleport_to(global_position) # only the player moves, world state stays put

	# kill the heartbeat loop before starting the fade out, otherwise they'd fight over the alpha
	if _aura_tween:
		_aura_tween.kill()
	create_tween().tween_property(_aura, "modulate:a", 0.0, 0.3)

	countdown_ended.emit()

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		_player_in_range = body

func _on_body_exited(body: Node) -> void:
	# only clear it if it's the same body leaving, don't want some other overlap wiping this out
	if body == _player_in_range:
		_player_in_range = null
