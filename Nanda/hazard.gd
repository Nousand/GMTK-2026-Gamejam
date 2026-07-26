extends Area2D

# generic contact hazard - reused for anything that should hurt the player just by touching it
# (saw, spiked ball...) instead of writing a near-identical script per trap type. drop
# this (plus whatever sprite/collision shape) into any scene and it works - finds the player via
# the "player" group, no hardcoded paths, same portability rule as the rest of Nanda's scripts.

@export var instant_kill: bool = true # spikes-style instant death vs. a take_hit life loss

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if instant_kill and body.has_method("die"):
		body.die()
	elif body.has_method("take_hit"):
		body.take_hit(self)
