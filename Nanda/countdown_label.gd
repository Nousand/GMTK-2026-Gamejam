extends Label

# shows whichever bell's countdown timer is currently active, hidden the rest of the time.
# connects to every bell in the "bell" group (not just one) since the map can have more than
# one bell. assumes the player can't ring a second bell while one is already counting down,
# so whichever bell rings just becomes the one being displayed.

#var _active_bell: Area2D = null

#func _ready() -> void:
#	visible = false # hidden until a bell actually gets rung
#	for bell in get_tree().get_nodes_in_group("bell"):
#		bell.rung.connect(_on_bell_rung.bind(bell))
#		bell.countdown_ended.connect(_on_bell_countdown_ended.bind(bell))

#func _process(_delta: float) -> void:
	# only update the text while the countdown is actually running, no point doing it every
	# frame otherwise
#	if _active_bell != null and _active_bell.is_timer_active:
#		text = "%.1f" % _active_bell.get_time_left()

#func _on_bell_rung(_duration: float, bell: Area2D) -> void:
#	_active_bell = bell
#	visible = true

#func _on_bell_countdown_ended(bell: Area2D) -> void:
#	if bell == _active_bell:
#		visible = false
#		_active_bell = null
