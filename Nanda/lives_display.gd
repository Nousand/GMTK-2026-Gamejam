extends HBoxContainer

# the heart row in the top-left of the HUD - shows one heart icon per life the player has.
# rebuilds itself from scratch every time the life count changes instead of trying to manage
# individual heart nodes, since lives aren't capped (heart pickups can push it past the
# starting amount) so we can't just have a fixed pool of 3 icons to show/hide.

# found via the "player" group instead of a scene path, so this can be dropped into any
# scene that has a Player node, regardless of where it sits in the tree
const HEART_SHEET := preload("res://Assets/Kings and Pigs/Sprites/12-Live and Coins/Big Heart Idle (18x14).png")
const HEART_FRAME_SIZE := Vector2(18, 14) # size of a single frame in the sheet above

@export var heart_scale: float = 2.0 # native sprite is tiny, scale it up so it actually reads on the HUD

var _player: Node

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_player.lives_changed.connect(_on_lives_changed)
	_on_lives_changed(_player.get_lives()) # draw the initial heart count right away, don't wait for the first change

# lives aren't capped (pickups keep adding more), so rebuild the row to match the count
# instead of just toggling a fixed set of icons on/off
func _on_lives_changed(current: int) -> void:
	# clear out whatever hearts were there before
	for child in get_children():
		remove_child(child)
		child.queue_free()

	# then build fresh ones, one per current life
	for i in current:
		# the heart sheet has multiple animation frames in it, we only want the first one as a
		# static icon, so we crop it down with an AtlasTexture instead of using the whole strip
		var frame := AtlasTexture.new()
		frame.atlas = HEART_SHEET
		frame.region = Rect2(Vector2.ZERO, HEART_FRAME_SIZE)

		var heart := TextureRect.new()
		heart.texture = frame
		heart.custom_minimum_size = HEART_FRAME_SIZE * heart_scale
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST # keep it crisp/pixelated when scaled up, not blurry
		add_child(heart)
