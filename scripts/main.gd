extends Control

enum Mode { BATTLE_ONLY, CENTER_BATTLE, LEFT_CENTER_BATTLE, CENTER_RIGHT_BATTLE, FULL }

var _current_mode := Mode.BATTLE_ONLY
var _full_size := Vector2i(1440, 720)
var _compact_size := Vector2i(1080, 180)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var win := get_window()
	win.borderless = true
	win.always_on_top = true
	win.unresizable = true
	win.transparent = true
	win.size = _compact_size
	win.position = Vector2i(100, 100)
	win.mouse_passthrough = false
	
	# 确保 DragHandle 可接收事件，ColorRect 不拦截
	var dh := $PanelRoot/BattleBar/DragHandle
	dh.mouse_filter = Control.MOUSE_FILTER_STOP
	dh.get_node("ColorRect").mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 信号连接
	$PanelRoot/BattleBar/Button.pressed.connect(_on_bag_button_pressed)
	$PanelRoot/CenterPanel/Button.pressed.connect(_on_left_button_pressed)
	$PanelRoot/CenterPanel/Button2.pressed.connect(_on_right_button_pressed)
	$PanelRoot/BattleBar/DragHandle.gui_input.connect(_on_drag_handle_input)
	
	# 初始 polygon
	_apply_passthrough()
	print("冒险者挂机 Boot OK")

# --- 拖动（仅用原生 start_drag）---
func _on_drag_handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_window().start_drag()

# --- 统一 polygon 构建：从 visible 面板 Rect2 包围盒推导 ---
func _apply_passthrough() -> void:
	var panel_root := $PanelRoot
	var rects: Array[Rect2] = []
	
	for panel_name in ["LeftPanel", "CenterPanel", "RightPanel", "BattleBar"]:
		var panel := panel_root.get_node(panel_name) as Control
		if panel and panel.visible:
			rects.append(panel.get_rect())
	
	if rects.is_empty():
		return
	
	var merged := rects[0]
	for i in range(1, rects.size()):
		merged = merged.merge(rects[i])
	
	var poly := PackedVector2Array()
	poly.append(merged.position)
	poly.append(Vector2(merged.end.x, merged.position.y))
	poly.append(merged.end)
	poly.append(Vector2(merged.position.x, merged.end.y))
	
	get_window().mouse_passthrough_polygon = poly
	
	# 调试日志
	var panel_names: Array[String] = []
	for panel_name in ["LeftPanel", "CenterPanel", "RightPanel", "BattleBar"]:
		var p := panel_root.get_node(panel_name) as Control
		if p and p.visible:
			panel_names.append(panel_name)
	print("PASSTHROUGH mode=%d size=%s panels=%s poly_rect=%s" % [
		_current_mode, get_window().size, ", ".join(panel_names), merged
	])

# --- 模式切换 ---
func _apply_mode(mode: Mode) -> void:
	_current_mode = mode
	var win := get_window()
	var panel_root := $PanelRoot
	var left := panel_root.get_node("LeftPanel")
	var center := panel_root.get_node("CenterPanel")
	var right := panel_root.get_node("RightPanel")
	var battle := panel_root.get_node("BattleBar")
	
	match mode:
		Mode.BATTLE_ONLY:
			win.size = _compact_size
			left.visible = false
			center.visible = false
			right.visible = false
			battle.position = Vector2(0, 0)
		Mode.CENTER_BATTLE:
			win.size = _full_size
			left.visible = false
			center.visible = true
			right.visible = false
			center.position = Vector2(360, 0)
			battle.position = Vector2(360, 540)
		Mode.LEFT_CENTER_BATTLE:
			win.size = _full_size
			left.visible = true
			center.visible = true
			right.visible = false
			left.position = Vector2(0, 0)
			center.position = Vector2(352, 0)
			battle.position = Vector2(360, 540)
		Mode.CENTER_RIGHT_BATTLE:
			win.size = _full_size
			left.visible = false
			center.visible = true
			right.visible = true
			center.position = Vector2(360, 0)
			right.position = Vector2(1088, 0)
			battle.position = Vector2(360, 540)
		Mode.FULL:
			win.size = _full_size
			left.visible = true
			center.visible = true
			right.visible = true
			left.position = Vector2(0, 0)
			center.position = Vector2(360, 0)
			right.position = Vector2(1088, 0)
			battle.position = Vector2(360, 540)
	
	_apply_passthrough()

# --- 按钮回调 ---
func _on_bag_button_pressed() -> void:
	if _current_mode == Mode.BATTLE_ONLY:
		_apply_mode(Mode.CENTER_BATTLE)
	else:
		_apply_mode(Mode.BATTLE_ONLY)
	print("BagButton pressed, mode=%d" % _current_mode)

func _on_left_button_pressed() -> void:
	match _current_mode:
		Mode.CENTER_BATTLE:
			_apply_mode(Mode.LEFT_CENTER_BATTLE)
		Mode.CENTER_RIGHT_BATTLE:
			_apply_mode(Mode.FULL)
		Mode.LEFT_CENTER_BATTLE:
			_apply_mode(Mode.CENTER_BATTLE)
		Mode.FULL:
			_apply_mode(Mode.CENTER_RIGHT_BATTLE)
	print("LeftButton pressed, mode=%d" % _current_mode)

func _on_right_button_pressed() -> void:
	match _current_mode:
		Mode.CENTER_BATTLE:
			_apply_mode(Mode.CENTER_RIGHT_BATTLE)
		Mode.LEFT_CENTER_BATTLE:
			_apply_mode(Mode.FULL)
		Mode.CENTER_RIGHT_BATTLE:
			_apply_mode(Mode.CENTER_BATTLE)
		Mode.FULL:
			_apply_mode(Mode.LEFT_CENTER_BATTLE)
	print("RightButton pressed, mode=%d" % _current_mode)
