extends Window

enum Mode { BATTLE_ONLY, CENTER_BATTLE, LEFT_CENTER_BATTLE, CENTER_RIGHT_BATTLE, FULL }

var _current_mode := -1
var _save_timer: Timer
var _is_dragging := false


func _ready() -> void:
	# 主机窗口隐藏
	hide()
	unfocusable = true
	gui_embed_subwindows = false

	# 加载场景中的子 Window 节点引用（它们已在 tscn 中作为子节点存在）
	var battle := $BattleWindow as Window
	var center := $CenterWindow as Window
	var left := $LeftWindow as Window
	var right := $RightWindow as Window

	# 设置各窗口初始属性（tscn 中已设但代码加固）
	for w in [battle, center, left, right]:
		w.transparent = true
		w.borderless = true
		w.always_on_top = true
		w.unresizable = true

	# 默认位置
	battle.position = Vector2i(360, 540)

	# 连接按钮信号
	battle.get_node("Button").pressed.connect(_on_bag_button_pressed)
	center.get_node("Button").pressed.connect(_on_left_button_pressed)
	center.get_node("Button2").pressed.connect(_on_right_button_pressed)

	# 防抖保存 Timer
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.3
	_save_timer.timeout.connect(_save_anchor)
	add_child(_save_timer)

	# 监听 BattleWindow 位置变化
	battle.position_changed.connect(_on_battle_position_changed)

	# 应用初始模式
	_apply_mode(Mode.BATTLE_ONLY)
	_load_anchor()

	print("冒险者多窗挂机 Boot OK")


func _on_battle_position_changed() -> void:
	if _is_dragging:
		return
	_reposition_windows()
	_save_timer.start()


func _reposition_windows() -> void:
	# 以 BattleWindow 为锚点重排其他可见窗口
	var battle := $BattleWindow as Window
	var center := $CenterWindow as Window
	var left := $LeftWindow as Window
	var right := $RightWindow as Window

	if center.visible:
		center.position = battle.position - Vector2i(0, center.size.y)
	if left.visible:
		left.position = center.position - Vector2i(left.size.x, 0)
	if right.visible:
		right.position = center.position + Vector2i(center.size.x, 0)


func _apply_mode(mode: Mode) -> void:
	if mode == _current_mode:
		return
	_current_mode = mode

	var battle := $BattleWindow as Window
	var center := $CenterWindow as Window
	var left := $LeftWindow as Window
	var right := $RightWindow as Window

	match mode:
		Mode.BATTLE_ONLY:
			battle.show()
			center.hide()
			left.hide()
			right.hide()
		Mode.CENTER_BATTLE:
			battle.show()
			center.show()
			left.hide()
			right.hide()
		Mode.LEFT_CENTER_BATTLE:
			battle.show()
			center.show()
			left.show()
			right.hide()
		Mode.CENTER_RIGHT_BATTLE:
			battle.show()
			center.show()
			left.hide()
			right.show()
		Mode.FULL:
			battle.show()
			center.show()
			left.show()
			right.show()

	_reposition_windows()
	_log_mode()


func _log_mode() -> void:
	var vis_parts: Array[String] = []
	var battle := $BattleWindow as Window
	var center := $CenterWindow as Window
	var left := $LeftWindow as Window
	var right := $RightWindow as Window
	if battle.visible: vis_parts.append("B")
	if left.visible: vis_parts.append("L")
	if center.visible: vis_parts.append("C")
	if right.visible: vis_parts.append("R")
	print("MODE mode=%d visible=%s battle_pos=(%d,%d)" % [
		_current_mode, "".join(vis_parts), battle.position.x, battle.position.y
	])


func _save_anchor() -> void:
	var battle := $BattleWindow as Window
	var config := ConfigFile.new()
	config.set_value("window", "battle_x", battle.position.x)
	config.set_value("window", "battle_y", battle.position.y)
	config.save("user://window.cfg")
	print("SAVE battle_pos=(%d,%d)" % [battle.position.x, battle.position.y])


func _load_anchor() -> bool:
	var battle := $BattleWindow as Window
	var config := ConfigFile.new()
	if config.load("user://window.cfg") != OK:
		return false
	var bx = config.get_value("window", "battle_x", null)
	var by = config.get_value("window", "battle_y", null)
	if bx == null or by == null:
		return false
	battle.position = Vector2i(int(bx), int(by))
	_reposition_windows()
	print("LOAD battle_pos=(%d,%d)" % [battle.position.x, battle.position.y])
	return true


func _on_bag_button_pressed() -> void:
	if _current_mode == Mode.BATTLE_ONLY:
		_apply_mode(Mode.CENTER_BATTLE)
	else:
		_apply_mode(Mode.BATTLE_ONLY)


func _on_left_button_pressed() -> void:
	match _current_mode:
		Mode.CENTER_BATTLE: _apply_mode(Mode.LEFT_CENTER_BATTLE)
		Mode.CENTER_RIGHT_BATTLE: _apply_mode(Mode.FULL)
		Mode.LEFT_CENTER_BATTLE: _apply_mode(Mode.CENTER_BATTLE)
		Mode.FULL: _apply_mode(Mode.CENTER_RIGHT_BATTLE)


func _on_right_button_pressed() -> void:
	match _current_mode:
		Mode.CENTER_BATTLE: _apply_mode(Mode.CENTER_RIGHT_BATTLE)
		Mode.LEFT_CENTER_BATTLE: _apply_mode(Mode.FULL)
		Mode.CENTER_RIGHT_BATTLE: _apply_mode(Mode.CENTER_BATTLE)
		Mode.FULL: _apply_mode(Mode.LEFT_CENTER_BATTLE)
