extends Area2D

# the bell - hit it with the hammer and it starts a countdown, then teleports whoever rang it
# back to the bell once time runs out. it's an Area2D (not a physics body), so it doesn't
# physically block anything, it just detects the hammer hitbox overlapping it.

# other scripts (obstacles, UI, whatever) can hook into these instead of polling the bell every frame
signal rung(duration: float) # fires the moment the bell gets hit and the countdown starts
signal countdown_ended() # fires the moment the countdown finishes and the player's back

@export var countdown_time: float = 90.0
@export var countdown_label: Label

# this is basically the whole state machine - true while the countdown is running.
# anything that needs to know if the bell is "live" can just check this directly.
var is_timer_active: bool = false

var _rung_player: CharacterBody2D = null # whoever actually rang it, so we know who to teleport back
var _aura_tween: Tween = null # keeping a handle on this so we can cancel the pulse loop later


@onready var _timer: Timer = $CountdownTimer
@onready var _ring_sound: AudioStreamPlayer2D = $RingSound
@onready var _swing: AnimationPlayer = $SwingAnimation
@onready var _aura: Sprite2D = $Aura

func _ready() -> void:
	add_to_group("bell") # lets UI (or anything else) find the bell without a hardcoded scene path
	add_to_group("hittable") # lets the player's attack hitbox find it via the shared take_hit contract
	_timer.wait_time = countdown_time
	_timer.one_shot = true # we restart it manually each ring, don't want it auto-looping
	_timer.timeout.connect(_on_timer_timeout)
	
	if countdown_label:
		countdown_label.visible = false
		
func _process(_delta: float) -> void:
	if is_timer_active and countdown_label:
		var time_left: float = get_time_left()
		countdown_label.text = "%.1f" % _timer.get_time_left()

# called by the player's attack hitbox when it swings into the bell - this is just the
# "hittable" contract, so from the player's side hitting the bell looks the same as hitting
# an enemy, it just happens to ring instead of taking damage
func take_hit(player: CharacterBody2D) -> void:
	ring(player)

func ring(player: CharacterBody2D) -> void:
	if is_timer_active:
		return # already rung, ignore extra hits until it resets

	is_timer_active = true
	_rung_player = player
	_timer.start()
	_ring_sound.play()
	_swing.play("swing")
	player.shake_camera()
	
	if countdown_label:
		countdown_label.visible = true

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

	if countdown_label:
		countdown_label.visible = false

	# kill the heartbeat loop before starting the fade out, otherwise they'd fight over the alpha
	if _aura_tween:
		_aura_tween.kill()
	create_tween().tween_property(_aura, "modulate:a", 0.0, 0.3)

	countdown_ended.emit()
