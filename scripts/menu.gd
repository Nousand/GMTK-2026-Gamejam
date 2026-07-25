extends Control

@onready var _play_button: Button = %PlayButton

func _ready() -> void:
	_play_button.grab_focus()
#Edit this
func _on_play_pressed() -> void:
	Global.reset_score()
	Global.change_scene("res://scenes/game.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
