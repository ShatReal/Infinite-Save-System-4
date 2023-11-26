extends Control


func _ready() -> void:
	Saves.game_loaded.connect(on_game_loaded)


func _on_save_load_pressed() -> void:
	Saves.popup_centered()


func get_text() -> String:
	return $TextEdit.text


func on_game_loaded(text: String) -> void:
	$TextEdit.text = text
