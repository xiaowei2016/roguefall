extends Panel

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var main = get_node("/root/MainRoot")
	if event.pressed:
		main.start_drag()
	else:
		main.end_drag()
