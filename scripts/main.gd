extends Control

# === 统一布局常量 ===
const _BATTLE_W := 720
const _BATTLE_H := 180
const _PANEL_W := 352
const _PANEL_H := 540
const _CENTER_W := 720
const _CENTER_H := 540
const _GAP := 8

enum Mode { BATTLE_ONLY, CENTER_BATTLE, LEFT_CENTER_BATTLE, CENTER_RIGHT_BATTLE, FULL }

var _current_mode := -1
var _save_timer: Timer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var win := get_window()
	win.borderless = true
	win.always_on_top = true
	win.unresizable = true
	win.transparent = true
	win.size = Vector2i(1440, 720)
	win.position = Vector2i(100, 100)
	win.mouse_passthrough = false
	
	# 固定节点位置（1440×720 透明画布，只需设置一次）
	$PanelRoot/LeftPanel.position = Vector2(0, 0)
	$PanelRoot/CenterPanel.position = Vector2(360, 0)
	$PanelRoot/RightPanel.position = Vector2(1088, 0)
	$PanelRoot/BattleBar.position = Vector2(360, 540)
	
	# 信号连接
	$PanelRoot/BattleBar/Button.pressed.connect(_on_bag_button_pressed)
	$PanelRoot/CenterPanel/Button.pressed.connect(_on_left_button_pressed)
	$PanelRoot/CenterPanel/Button2.pressed.connect(_on_right_button_pressed)
	
	# 防抖保存 Timer
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.3
	_save_timer.timeout.connect(_save_anchor)
	add_child(_save_timer)
	
	# 先应用 BattleOnly 布局，再加载保存的 BattleBar 锚点
	_apply_mode(Mode.BATTLE_ONLY)
	_load_anchor()
	
	print("冒险者挂机 Boot OK")


# === Polygon：从可见 Control 的 Rect2 推导，禁止魔法数字 ===
func _apply_passthrough() -> void:
	var panel_root := $PanelRoot
	var rects: Array[Rect2] = []
	
	for name in ["LeftPanel", "CenterPanel", "RightPanel", "BattleBar"]:
		var p := panel_root.get_node(name) as Control
		if p and p.visible:
			rects.append(Rect2(p.position, p.size))
	
	var poly := _rects_to_polygon(rects)
	get_window().mouse_passthrough_polygon = poly


func _rects_to_polygon(rects: Array[Rect2]) -> PackedVector2Array:
	if rects.is_empty():
		return PackedVector2Array()
	
	# 单矩形
	if rects.size() == 1:
		var r := rects[0]
		return PackedVector2Array([
			r.position,
			Vector2(r.end.x, r.position.y),
			r.end,
			Vector2(r.position.x, r.end.y),
		])
	
	# 两矩形且对齐（矩形叠加）：如 CenterBattle
	if rects.size() == 2:
		var r1 := rects[0]
		var r2 := rects[1]
		if is_equal_approx(r1.position.x, r2.position.x) and is_equal_approx(r1.size.x, r2.size.x):
			var m := r1.merge(r2)
			return PackedVector2Array([
				m.position,
				Vector2(m.end.x, m.position.y),
				m.end,
				Vector2(m.position.x, m.end.y),
			])
	
	# 3+ 矩形：从 panel rects 推导 T/L 形轮廓
	var merged := rects[0]
	for i in range(1, rects.size()):
		merged = merged.merge(rects[i])
	
	# 战斗条在面板下方居中 → 多边形有底部凹槽
	var bb := $PanelRoot/BattleBar as Control
	var bar_left := bb.position.x
	var bar_right := bb.position.x + bb.size.x
	var bar_top := bb.position.y
	
	var lx := merged.position.x
	var rx := merged.end.x
	var ty := merged.position.y
	var by := merged.end.y
	
	return PackedVector2Array([
		Vector2(lx, ty),             # 左上
		Vector2(rx, ty),             # 右上
		Vector2(rx, bar_top),        # 右侧凹槽上沿
		Vector2(bar_right, bar_top), # 战斗条右上
		Vector2(bar_right, by),      # 战斗条右下
		Vector2(bar_left, by),       # 战斗条左下
		Vector2(bar_left, bar_top),  # 战斗条左上
		Vector2(lx, bar_top),        # 左侧凹槽上沿
	])


# === 屏幕边界限制 ===
func _clamp_to_screen() -> void:
	var win := get_window()
	var screen_i := win.current_screen
	var screen := DisplayServer.screen_get_usable_rect(screen_i)
	var pos := win.get_position()
	var sz := win.get_size()
	
	var min_x := screen.position.x
	var max_x := screen.position.x + screen.size.x - sz.x
	var min_y := screen.position.y
	var max_y := screen.position.y + screen.size.y - sz.y
	
	pos.x = clampi(pos.x, min_x, max_x)
	pos.y = clampi(pos.y, min_y, max_y)
	
	win.position = pos


# === 窗口通知：移动后防抖保存，关闭时立即保存 ===
func _notification(what: int) -> void:
	if what == Window.NOTIFICATION_WM_POSITION_CHANGED:
		_save_timer.start()
	elif what == Window.NOTIFICATION_WM_CLOSE_REQUEST:
		_save_anchor()
		get_tree().quit()


# === 保存 BattleBar 屏幕锚点到 user://window.cfg ===
func _save_anchor() -> void:
	var win := get_window()
	var battle := $PanelRoot/BattleBar
	var anchor: Vector2i = win.position + Vector2i(battle.position)
	
	var config := ConfigFile.new()
	config.set_value("window", "battle_anchor_x", anchor.x)
	config.set_value("window", "battle_anchor_y", anchor.y)
	config.save("user://window.cfg")
	print("SAVE anchor=(%d,%d)" % [anchor.x, anchor.y])


# === 从 user://window.cfg 恢复 BattleBar 屏幕锚点 ===
func _load_anchor() -> bool:
	var config := ConfigFile.new()
	var err := config.load("user://window.cfg")
	if err != OK:
		return false
	
	var ax = config.get_value("window", "battle_anchor_x", null)
	var ay = config.get_value("window", "battle_anchor_y", null)
	if ax == null or ay == null:
		return false
	
	var saved_anchor := Vector2i(int(ax), int(ay))
	var battle_pos := Vector2i($PanelRoot/BattleBar.position)
	var win := get_window()
	win.position = saved_anchor - battle_pos
	
	_clamp_to_screen()
	print("LOAD anchor=(%d,%d) window_pos=(%d,%d)" % [saved_anchor.x, saved_anchor.y, win.position.x, win.position.y])
	return true


# === 模式切换（固定 1440×720 画布，只切 visible + polygon）===
func _apply_mode(mode: Mode) -> void:
	if mode == _current_mode:
		print("MODE apply once mode=%d" % mode)
		return
	_current_mode = mode
	
	var left := $PanelRoot/LeftPanel
	var center := $PanelRoot/CenterPanel
	var right := $PanelRoot/RightPanel
	var battle := $PanelRoot/BattleBar
	
	match mode:
		Mode.BATTLE_ONLY:
			left.visible = false
			center.visible = false
			right.visible = false
			battle.visible = true
		Mode.CENTER_BATTLE:
			left.visible = false
			center.visible = true
			right.visible = false
			battle.visible = true
		Mode.LEFT_CENTER_BATTLE:
			left.visible = true
			center.visible = true
			right.visible = false
			battle.visible = true
		Mode.CENTER_RIGHT_BATTLE:
			left.visible = false
			center.visible = true
			right.visible = true
			battle.visible = true
		Mode.FULL:
			left.visible = true
			center.visible = true
			right.visible = true
			battle.visible = true
	
	_apply_passthrough()
	_log_layout()


# === 布局日志 ===
func _log_layout() -> void:
	var win := get_window()
	var left := $PanelRoot/LeftPanel
	var center := $PanelRoot/CenterPanel
	var right := $PanelRoot/RightPanel
	var battle := $PanelRoot/BattleBar
	
	var parts: Array[String] = []
	parts.append("mode=%d" % _current_mode)
	parts.append("window_size=(%d,%d)" % [win.size.x, win.size.y])
	
	# 可见面板
	var vis_parts: Array[String] = []
	if battle.visible: vis_parts.append("B")
	if left.visible: vis_parts.append("L")
	if center.visible: vis_parts.append("C")
	if right.visible: vis_parts.append("R")
	parts.append("visible=%s" % "".join(vis_parts))
	
	# Polygon
	var poly := get_window().mouse_passthrough_polygon
	var pts: Array[String] = []
	for v in poly:
		pts.append("(%d,%d)" % [int(v.x), int(v.y)])
	parts.append("polygon_points=[%s]" % ", ".join(pts))
	
	print("MODE %s" % " | ".join(parts))


# === 按钮回调 ===
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
