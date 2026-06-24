extends Panel


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("DRAG native zone=%s" % get_path())
			get_window().start_drag()
