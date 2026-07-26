extends Node2D

# swings the ball on its chain like a pendulum. this node's own origin is the ceiling anchor
# point - the chain links and the ball (see spiked_ball.tscn) all hang below it as children, so
# rotating this node swings the whole rig together instead of animating each piece separately.

@export var swing_degrees: float = 40.0
@export var swing_time: float = 1.5

func _ready() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation_degrees", swing_degrees, swing_time)
	tween.tween_property(self, "rotation_degrees", -swing_degrees, swing_time * 2.0)
	tween.tween_property(self, "rotation_degrees", 0.0, swing_time)
