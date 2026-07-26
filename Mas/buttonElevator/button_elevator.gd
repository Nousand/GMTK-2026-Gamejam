extends AnimatableBody2D

signal elevator_started

@export var move_range: float = 200.0        # How far the platform moves UP from start (pixels)
@export var move_duration: float = 5.0       # Time to move from one extreme to the other (seconds)
@export var pause_duration: float = 2.0      # Time to pause at each extreme (seconds)
@export var start_offset: float = 0.0        # Starting position offset (0-1) - 0 = bottom, 1 = top

var start_position: Vector2  # This is the BOTTOM position
var state: String = "idle"
var cycle_time: float = 0.0
var is_moving: bool = false
var has_started: bool = false


func _ready() -> void:
	start_position = position  # Store the bottom position
	# Set initial position based on offset - 0 = bottom, 1 = top
	var initial_progress = clamp(start_offset, 0.0, 1.0)
	position.y = start_position.y - initial_progress * move_range  # Negative because Y goes up
	
	# Force idle state
	state = "idle"
	is_moving = false
	has_started = false


func _physics_process(delta: float) -> void:
	if not is_moving or not has_started:
		return
	
	cycle_time += delta
	
	match state:
		"moving_up":
			# Move up (decrease y) from bottom to top
			var progress = cycle_time / move_duration
			if progress >= 1.0:
				# Reached top, start pause
				state = "pausing_top"
				cycle_time = 0.0
			else:
				# Ease in/out for smooth movement
				var eased_progress = ease(progress, 0.5)
				position.y = start_position.y - eased_progress * move_range
		
		"pausing_top":
			if cycle_time >= pause_duration:
				# Pause finished, start moving down
				state = "moving_down"
				cycle_time = 0.0
		
		"moving_down":
			# Move down (increase y) from top to bottom
			var progress = cycle_time / move_duration
			if progress >= 1.0:
				# Reached bottom, start pause
				state = "pausing_bottom"
				cycle_time = 0.0
			else:
				# Ease in/out for smooth movement
				var eased_progress = ease(progress, 0.5)
				position.y = start_position.y - (1.0 - eased_progress) * move_range
		
		"pausing_bottom":
			if cycle_time >= pause_duration:
				# Pause finished, start moving up
				state = "moving_up"
				cycle_time = 0.0


func start_elevator() -> void:
	if not has_started and not is_moving:
		has_started = true
		is_moving = true
		elevator_started.emit()
		
		# Calculate current progress from bottom (0 = bottom, 1 = top)
		var current_progress = (start_position.y - position.y) / move_range
		current_progress = clamp(current_progress, 0.0, 1.0)
		
		if current_progress <= 0.0:
			state = "moving_up"
		elif current_progress >= 1.0:
			state = "moving_down"
		else:
			state = "moving_up"
		
		cycle_time = current_progress * move_duration
