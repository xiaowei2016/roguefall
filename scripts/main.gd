extends Control

# 布局常量
const _LEFT_W := 352
const _LEFT_H := 530
const _CENTER_W := 720
const _CENTER_H := 530
const _RIGHT_W := 352
const _RIGHT_H := 530
const _BATTLE_W := 720
const _BATTLE_H := 180
const _GAP_H := 8
const _GAP_V := 10
const _FULL_W := 1440  # _LEFT_W + _RIGHT_W + _CENTER_W + 2*_GAP_H
const _FULL_H := 720  # _LEFT_H + _BATTLE_H + _GAP_V
const _COMPACT_W := 1080
const _COMPACT_H := 180

const _CENTER_X := _LEFT_W + _GAP_H
const _RIGHT_X := _CENTER_X + _CENTER_W + _GAP_H
const _BATTLE_X := _LEFT_W + _GAP_H
const _BATTLE_Y := _LEFT_H + _GAP_V

enum Mode { BATTLE_ONLY, CENTER_BATTLE, LEFT_CENTER_BATTLE, CENTER_RIGHT_BATTLE, FULL }

var _current_mode := Mode.BATTLE_ONLY


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var win := get_window()
	win.borderless = true
	win.always_on_top = true
	win.unresizable = true
	win.transparent = true
	win.size = Vector2i(_COMPACT_W, _COMPACT_H)
	win.position = Vector2i(100, 100)
	win.mouse_passthrough = false
	
	# 信号连接
	$PanelRoot/BattleBar/Button.pressed.connect(_on_bag_button_pressed)
	$PanelRoot/CenterPanel/Button.pressed.connect(_on_left_button_pressed)
	$PanelRoot/CenterPanel/Button2.pressed.connect(_on_right_button_pressed)
	
	# 初始化
	_apply_passthrough()
	print("冒险者挂机 Boot OK")


# --- 原生 polygon：每个模式生成真实 PackedVector2Array ---
func _apply_passthrough() -> void:
	var poly: PackedVector2Array
	
	match _current_mode:
		Mode.BATTLE_ONLY:
			# BattleBar (0,0)-(BATTLE_W,BATTLE_H) 在紧凑窗口中
			poly = PackedVector2Array([
				Vector2(0, 0),
				Vector2(_BATTLE_W, 0),
				Vector2(_BATTLE_W, _BATTLE_H),
				Vector2(0, _BATTLE_H),
			])
		Mode.CENTER_BATTLE:
			# CenterPanel + BattleBar 720×720 @ (_CENTER_X,0)
			poly = PackedVector2Array([
				Vector2(_CENTER_X, 0),
				Vector2(_CENTER_X + _CENTER_W, 0),
				Vector2(_CENTER_X + _CENTER_W, _FULL_H),
				Vector2(_CENTER_X, _FULL_H),
			])
		Mode.LEFT_CENTER_BATTLE:
			# 左栏+中栏+底部中间的 L/T 形
			var center_right := _LEFT_W + _CENTER_W   # 1072
			var battle_right := _BATTLE_X + _BATTLE_W  # 1080
			poly = PackedVector2Array([
				Vector2(0, 0),
				Vector2(center_right, 0),
				Vector2(center_right, _LEFT_H),
				Vector2(battle_right, _LEFT_H),
				Vector2(battle_right, _FULL_H),
				Vector2(_BATTLE_X, _FULL_H),
				Vector2(_BATTLE_X, _LEFT_H),
				Vector2(0, _LEFT_H),
			])
		Mode.CENTER_RIGHT_BATTLE:
			# 中栏+右栏+底部中间的 L/T 形
			var battle_right := _BATTLE_X + _BATTLE_W  # 1080
			poly = PackedVector2Array([
				Vector2(_CENTER_X, 0),
				Vector2(_FULL_W, 0),
				Vector2(_FULL_W, _LEFT_H),
				Vector2(battle_right, _LEFT_H),
				Vector2(battle_right, _FULL_H),
				Vector2(_CENTER_X, _FULL_H),
			])
		Mode.FULL:
			# 三栏顶部 + 底部中间战斗条的 T 形
			# 形状等价: [(0,0),(1440,0),(1440,540),(1080,540),(1080,720),(360,720),(360,540),(0,540)]
			var battle_right := _BATTLE_X + _BATTLE_W  # 1080
			poly = PackedVector2Array([
				Vector2(0, 0),
				Vector2(_FULL_W, 0),
				Vector2(_FULL_W, _BATTLE_Y),
				Vector2(battle_right, _BATTLE_Y),
				Vector2(battle_right, _FULL_H),
				Vector2(_BATTLE_X, _FULL_H),
				Vector2(_BATTLE_X, _BATTLE_Y),
				Vector2(0, _BATTLE_Y),
			])
	
	get_window().mouse_passthrough_polygon = poly
	
	# 日志打印 polygon_points
	var pts: Array[String] = []
	for v in poly:
		pts.append("(%d,%d)" % [int(v.x), int(v.y)])
	print("PASSTHROUGH mode=%d size=%s polygon_points=[%s]" % [
		_current_mode, get_window().size, ", ".join(pts)
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
			win.size = Vector2i(_COMPACT_W, _COMPACT_H)
			left.visible = false
			center.visible = false
			right.visible = false
			battle.position = Vector2(0, 0)
		Mode.CENTER_BATTLE:
			win.size = Vector2i(_FULL_W, _FULL_H)
			left.visible = false
			center.visible = true
			right.visible = false
			center.position = Vector2(_CENTER_X, 0)
			battle.position = Vector2(_BATTLE_X, _BATTLE_Y)
		Mode.LEFT_CENTER_BATTLE:
			win.size = Vector2i(_FULL_W, _FULL_H)
			left.visible = true
			center.visible = true
			right.visible = false
			left.position = Vector2(0, 0)
			center.position = Vector2(_LEFT_W, 0)
			battle.position = Vector2(_BATTLE_X, _BATTLE_Y)
		Mode.CENTER_RIGHT_BATTLE:
			win.size = Vector2i(_FULL_W, _FULL_H)
			left.visible = false
			center.visible = true
			right.visible = true
			center.position = Vector2(_CENTER_X, 0)
			right.position = Vector2(_RIGHT_X, 0)
			battle.position = Vector2(_BATTLE_X, _BATTLE_Y)
		Mode.FULL:
			win.size = Vector2i(_FULL_W, _FULL_H)
			left.visible = true
			center.visible = true
			right.visible = true
			left.position = Vector2(0, 0)
			center.position = Vector2(_CENTER_X, 0)
			right.position = Vector2(_RIGHT_X, 0)
			battle.position = Vector2(_BATTLE_X, _BATTLE_Y)
	
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
