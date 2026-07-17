extends Node

enum State { MENU, PLAYING, GAME_OVER }

var current_state: State = State.MENU
var score: float = 0.0

func change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func reset_score() -> void:
	score = 0.0
