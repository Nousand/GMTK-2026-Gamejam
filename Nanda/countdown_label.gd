extends Label

# found via the "bell" group instead of a scene path, so this label can be dropped into any
# scene that has a Bell node, regardless of where it sits in the tree
var _bell: Area2D

func _ready() -> void:
	visible = false # hidden until the bell actually gets rung
	_bell = get_tree().get_first_node_in_group("bell")
	_bell.rung.connect(_on_bell_rung)
	_bell.countdown_ended.connect(_on_bell_countdown_ended)

func _process(_delta: float) -> void:
	if _bell.is_timer_active:
		text = "%.1f" % _bell.get_time_left()

func _on_bell_rung(_duration: float) -> void:
	visible = true

func _on_bell_countdown_ended() -> void:
	visible = false
