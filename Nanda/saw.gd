extends Node2D

@export var travel_distance: float = 200.0 # how far along the track it travels while visible
@export var dip_depth: float = 64.0 # how far it retreats out of sight while hidden
@export var mounted_on_ceiling: bool = false # true = retreats upward into the ceiling instead of down into the floor
@export var travel_time: float = 1.2 # time to cross the track, one direction
@export var dip_time: float = 0.4 # time spent retreating/re-emerging (and fading)
@export var hidden_pause: float = 0.4 # how long it waits hidden before it re-emerges

@onready var _blade: Area2D = $Blade

func _ready() -> void:
	var retreat_offset := Vector2(0, -dip_depth if mounted_on_ceiling else dip_depth)
	var visible_start := position
	var visible_end := visible_start + Vector2(travel_distance, 0)
	var hidden_end := visible_end + retreat_offset
	var hidden_start := visible_start + retreat_offset

	var loop := create_tween()
	loop.set_loops()

	loop.tween_property(self, "position", visible_end, travel_time) # visible run across the track

	loop.tween_property(self, "position", hidden_end, dip_time) # retreat...
	loop.parallel().tween_property(self, "modulate:a", 0.0, dip_time) # ...fading out as it goes
	loop.tween_callback(_set_hidden.bind(true))

	loop.tween_property(self, "position", hidden_start, travel_time) # travel back, hidden
	loop.tween_interval(hidden_pause) # wait hidden before re-emerging

	loop.tween_callback(_set_hidden.bind(false))
	loop.tween_property(self, "position", visible_start, dip_time) # re-emerge...
	loop.parallel().tween_property(self, "modulate:a", 1.0, dip_time) # ...fading back in

# hidden = tucked away in the floor/ceiling: harmless, so it can't hit the player through it
func _set_hidden(hidden: bool) -> void:
	_blade.monitoring = not hidden
	_blade.monitorable = not hidden
