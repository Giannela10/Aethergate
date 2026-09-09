extends Control


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://demo/Demo.tscn")


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://Scrips/Options.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
