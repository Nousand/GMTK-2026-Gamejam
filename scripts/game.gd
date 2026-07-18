extends Node2D

@onready var score_label: Label = $ScoreLabel

func _process(delta: float) -> void:
	Global.score += delta
	score_label.text = "Score: %d" % int(Global.score)

	if Input.is_action_just_pressed("ui_cancel"):
		Global.change_scene("res://scenes/game_over.tscn")
