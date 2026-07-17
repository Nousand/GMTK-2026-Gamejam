extends Node2D

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		Global.reset_score()
		Global.change_scene("res://scenes/game.tscn")
