# ============================================================
# battle_widget_drag.gd - BattleWidget 容器内拖动 + 边缘推窗 + Center跟随
# ============================================================
# 功能：拖动 BattleWidget 在窗口内移动；触碰边缘时用溢出量推动
#       OS 窗口。CenterDockHost 跟随到 BattleWidget 上方或下方。
#       仅位置/窗口实际变化时刷新 passthrough。
# 挂载：BattleWidget 节点
# ============================================================
extends Control


var _dragging := false
var _last_pos: Vector2 = Vector2.ZERO
var _last_win_pos: Vector2i = Vector2i.ZERO


func _ready() -> void:
	_last_pos = position
	_last_win_pos = get_window().position


# --------------------------------------------------
# _layout_center_around_battle()
# --------------------------------------------------
# CenterDockHost 跟随 BattleWidget：优先放上方，上方不足放下方。
# 仅当 CenterDockHost.visible 时生效。
func _layout_center_around_battle() -> void:
	var center = get_node_or_null("../DockLayer/CenterDockHost") as Control
	if not center or not center.visible:
		return

	var win_size := get_window().size
	var center_h: float = center.size.y  # 530
	var battle_h: float = size.y          # 180
	var gap := 10.0

	# Align x
	center.position.x = clamp(position.x, 0.0, win_size.x - center.size.x)

	# Try above first
	var above_y := position.y - center_h - gap
	if above_y >= 0:
		center.position.y = above_y
	else:
		# Below
		center.position.y = position.y + battle_h + gap

	# Clamp y
	center.position.y = clamp(center.position.y, 0.0, win_size.y - center_h)

	print("LAYOUT center=(%.0f,%.0f) %s" % [
		center.position.x, center.position.y,
		"above" if center.position.y < position.y else "below"
	])


# --------------------------------------------------
# _gui_input(event) - 处理鼠标输入
# --------------------------------------------------
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			if not _dragging:
				# 松手时记录最终位置
				_last_pos = position
				_last_win_pos = get_window().position

	if not _dragging:
		return

	if event is InputEventMouseMotion:
		var win := get_window()
		var win_size := win.size

		var next_pos: Vector2 = position + event.relative

		var overflow_x: float = 0.0
		var overflow_y: float = 0.0

		if next_pos.x < 0:
			overflow_x = next_pos.x
			next_pos.x = 0
		elif next_pos.x + size.x > win_size.x:
			overflow_x = next_pos.x + size.x - win_size.x
			next_pos.x = win_size.x - size.x

		if next_pos.y < 0:
			overflow_y = next_pos.y
			next_pos.y = 0
		elif next_pos.y + size.y > win_size.y:
			overflow_y = next_pos.y + size.y - win_size.y
			next_pos.y = win_size.y - size.y

		position = next_pos

		if overflow_x != 0.0 or overflow_y != 0.0:
			var win_pos := win.position
			win.position = win_pos + Vector2i(int(overflow_x), int(overflow_y))

		# 仅位置/窗口实际变化时刷新
		var pos_changed := position.distance_squared_to(_last_pos) > 0.01
		var win_changed := win.position != _last_win_pos

		if pos_changed or win_changed:
			_last_pos = position
			_last_win_pos = win.position
			print("DRAG pos=(%.0f,%.0f) overflow=(%.0f,%.0f) win=%s" % [
				position.x, position.y,
				overflow_x, overflow_y,
				win.position
			])
			# 先布局 Center 跟随，再刷新 passthrough
			_layout_center_around_battle()
			get_node("../InputRegionManager").apply_current_visible_passthrough()
