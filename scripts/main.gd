extends Control

# 五模式枚举
enum Mode { BATTLE_ONLY, CENTER_BATTLE, LEFT_CENTER_BATTLE, CENTER_RIGHT_BATTLE, FULL }

var _current_mode := Mode.BATTLE_ONLY
var _full_size := Vector2i(1440, 720)
var _compact_size := Vector2i(1080, 180)

func _ready() -> void:
	# 根节点 mouse_filter=IGNORE 让整个窗口背景穿透
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 设置原生窗口属性
	var win := get_window()
	win.borderless = true
	win.always_on_top = true
	win.unresizable = true
	win.transparent = true
	win.size = _compact_size
	win.position = Vector2i(100, 100)
	# mouse_passthrough 必须 false，否则 polygon 被忽略
	win.mouse_passthrough = false
	# 初始 BATTLE_ONLY 模式 polygon
	_set_passthrough_battle_only()
	
	# 信号连接
	$PanelRoot/BattleBar/Button.pressed.connect(_on_bag_button_pressed)
	$PanelRoot/CenterPanel/Button.pressed.connect(_on_left_button_pressed)
	$PanelRoot/CenterPanel/Button2.pressed.connect(_on_right_button_pressed)
	$PanelRoot/BattleBar/DragHandle.gui_input.connect(_on_drag_handle_input)
	
	print("冒险者挂机 Boot OK")

# --- 拖动 ---
func _on_drag_handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_window().start_drag()

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
			_set_passthrough_battle_only()
		Mode.CENTER_BATTLE:
			win.size = _full_size
			left.visible = false
			center.visible = true
			right.visible = false
			center.position = Vector2(360, 0)
			battle.position = Vector2(360, 540)
			_set_passthrough_center_battle()
		Mode.LEFT_CENTER_BATTLE:
			win.size = _full_size
			left.visible = true
			center.visible = true
			right.visible = false
			left.position = Vector2(0, 0)
			center.position = Vector2(352, 0)
			battle.position = Vector2(360, 540)
			_set_passthrough_left_center_battle()
		Mode.CENTER_RIGHT_BATTLE:
			win.size = _full_size
			left.visible = false
			center.visible = true
			right.visible = true
			center.position = Vector2(360, 0)
			right.position = Vector2(1088, 0)
			battle.position = Vector2(360, 540)
			_set_passthrough_center_right_battle()
		Mode.FULL:
			win.size = _full_size
			left.visible = true
			center.visible = true
			right.visible = true
			left.position = Vector2(0, 0)
			center.position = Vector2(360, 0)
			right.position = Vector2(1088, 0)
			battle.position = Vector2(360, 540)
			_set_passthrough_full()

# --- Polygon 设置（严格只使用 Window.mouse_passthrough_polygon）---
func _set_passthrough_battle_only() -> void:
	var poly := PackedVector2Array()
	# BattleBar 在 compact 窗口 (1080x180) 铺满
	poly.append(Vector2(0, 0))
	poly.append(Vector2(1080, 0))
	poly.append(Vector2(1080, 180))
	poly.append(Vector2(0, 180))
	get_window().mouse_passthrough_polygon = poly

func _set_passthrough_center_battle() -> void:
	var poly := PackedVector2Array()
	poly.append(Vector2(0, 0))
	poly.append(Vector2(1440, 0))
	poly.append(Vector2(1440, 540))
	poly.append(Vector2(1080, 540))
	poly.append(Vector2(1080, 720))
	poly.append(Vector2(360, 720))
	poly.append(Vector2(360, 540))
	poly.append(Vector2(0, 540))
	get_window().mouse_passthrough_polygon = poly

func _set_passthrough_left_center_battle() -> void:
	var poly := PackedVector2Array()
	poly.append(Vector2(0, 0))
	poly.append(Vector2(1440, 0))
	poly.append(Vector2(1440, 540))
	poly.append(Vector2(1080, 540))
	poly.append(Vector2(1080, 720))
	poly.append(Vector2(360, 720))
	poly.append(Vector2(360, 540))
	poly.append(Vector2(0, 540))
	get_window().mouse_passthrough_polygon = poly

func _set_passthrough_center_right_battle() -> void:
	var poly := PackedVector2Array()
	poly.append(Vector2(0, 0))
	poly.append(Vector2(1440, 0))
	poly.append(Vector2(1440, 540))
	poly.append(Vector2(1080, 540))
	poly.append(Vector2(1080, 720))
	poly.append(Vector2(360, 720))
	poly.append(Vector2(360, 540))
	poly.append(Vector2(0, 540))
	get_window().mouse_passthrough_polygon = poly

func _set_passthrough_full() -> void:
	var poly := PackedVector2Array()
	poly.append(Vector2(0, 0))
	poly.append(Vector2(1440, 0))
	poly.append(Vector2(1440, 720))
	poly.append(Vector2(0, 720))
	get_window().mouse_passthrough_polygon = poly

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
