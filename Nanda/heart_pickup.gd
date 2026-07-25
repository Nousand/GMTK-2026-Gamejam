extends Area2D

# a heart sitting in the level that grants the player an extra life when hit with the hammer.
# uses the same "hittable" group + take_hit(attacker) contract as the bell and enemies, so it
# plugs straight into the player's existing attack code without the player needing to know
# hearts even exist.

func _ready() -> void:
	add_to_group("hittable") # lets the player's attack hitbox find it via the shared take_hit contract

# the player's attack hitbox calls this when the hammer connects
func take_hit(attacker: Node) -> void:
	if attacker.has_method("add_life"):
		attacker.add_life()
	queue_free() # one-time pickup, remove it once it's been collected
