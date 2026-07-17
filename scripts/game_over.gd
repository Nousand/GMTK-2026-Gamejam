extends Node2D

@onready var score_label: Label = $ScoreLabel

func _ready() -> void:
	score_label.text = "Final Score: %d" % int(Global.score)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		Global.change_scene("res://scenes/menu.tscn")
