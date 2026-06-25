extends Control

const EDGE_MARGIN := 16
const GAP := 8
const BATTLE_H := 180
const PANEL_H := 530
const WIN_W := 1440
const WIN_H := 718     # 530 + 8 + 180，翻转就是上下对调
const FLIP_BOT := 538   # 战斗条默认窗口内 y，仅 _ready 初始锚点推导用
const PW := 352    # 左/右面板宽度
const CW := 720    # 中栏宽度
const FLIP_HYSTERESIS := 24
const LOG_THROTTLE := 30

const BATTLE_REST_X := 360

enum Mode { BATTLE_ONLY, CENTER_BATTLE, LEFT_CENTER_BATTLE, CENTER_RIGHT_BATTLE, FULL }

var _loading := true
var _current_mode := -1
var _dragging := false

# 拖拽：鼠标屏幕坐标与锚点之间的固定偏移
var _drag_offset_x := 0
var _drag_offset_y := 0

# BattleBar 屏幕坐标锚点，唯一拖拽真源
var _battle_anchor_screen_x := 0
var _battle_anchor_screen_y := 0

# 上下翻转滞后
var _last_flipped: bool = false

# 日志节流
var _last_log_mode: int = -1
var _last_log_flipped: bool = false
var _last_log_shift: int = 0
var _log_frame_count: int = 0

@onready var battle_bar := $PanelRoot/BattleBar
@onready var left_panel := $PanelRoot/LeftPanel
@onready var center_panel := $PanelRoot/CenterPanel
@onready var right_panel := $PanelRoot/RightPanel


func _ready() -> void:
	_loading = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var win := get_window()
	win.borderless = true
	win.always_on_top = true
	win.unresizable = true
	win.transparent = true
	win.size = Vector2i(WIN_W, WIN_H)

	$PanelRoot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	$PanelRoot/BattleBar/Button.pressed.connect(_on_bag)
	$PanelRoot/CenterPanel/Button.pressed.connect(_on_left)
	$PanelRoot/CenterPanel/Button2.pressed.connect(_on_right)

	battle_bar.position.y = FLIP_BOT

	if not _load_position():
		_center_on_screen()

	# 从当前窗口位置和 tscn 默认 battle_bar 位置推导初始值
	_battle_anchor_screen_x = win.position.x + int(battle_bar.position.x)
	_battle_anchor_screen_y = win.position.y + int(battle_bar.position.y)

	_apply_mode(Mode.BATTLE_ONLY)
	_loading = false
	print("[roguefall] INIT OK  mode=%d  win=(%d,%d)  size=(%d,%d)  anchor=(%d,%d)  rest_x=%d" % [
		_current_mode, win.position.x, win.position.y, win.size.x, win.size.y,
		_battle_anchor_screen_x, _battle_anchor_screen_y, BATTLE_REST_X
	])


# ===== 模式 =====
func _apply_mode(mode: Mode) -> void:
	if mode == _current_mode:
		return
	_current_mode = mode

	left_panel.visible = (mode == Mode.LEFT_CENTER_BATTLE or mode == Mode.FULL)
	center_panel.visible = (mode != Mode.BATTLE_ONLY)
	right_panel.visible = (mode == Mode.CENTER_RIGHT_BATTLE or mode == Mode.FULL)

	_do_layout()
	_update_passthrough()



# ===== 布局（screen-space stateless） =====
func _do_layout() -> void:
	var win := get_window()
	var screen := DisplayServer.screen_get_usable_rect(win.current_screen)

	var screen_min_x := screen.position.x + EDGE_MARGIN
	var screen_max_x := screen.position.x + screen.size.x - EDGE_MARGIN
	var has_panels := _current_mode != Mode.BATTLE_ONLY

	# ---- 1. BattleBar screen rect（锚点是 BattleBar 左上角） ----
	var bb_sx := _battle_anchor_screen_x
	var bb_sy := _battle_anchor_screen_y
	var bb_sw := CW   # 720
	var bb_sh := BATTLE_H

	# ---- 2. 面板 screen y（翻转逻辑） ----
	var flipped: bool = false
	var panel_sy: int = 0

	if has_panels:
		var space_above := bb_sy - screen.position.y - EDGE_MARGIN
		var space_below := screen.position.y + screen.size.y - (bb_sy + bb_sh) - EDGE_MARGIN

		if _dragging:
			if _last_flipped:
				flipped = space_above + FLIP_HYSTERESIS < space_below
			else:
				flipped = space_below > space_above + FLIP_HYSTERESIS
		else:
			flipped = space_above < space_below
		_last_flipped = flipped

		if flipped:
			panel_sy = bb_sy + bb_sh + GAP   # 面板在 BattleBar 下方
		else:
			panel_sy = bb_sy - PANEL_H - GAP # 面板在 BattleBar 上方

	# ---- 3. 面板 screen x（以 BattleBar screen x 对齐 CenterPanel） ----
	var center_sx := bb_sx
	var left_sx   := center_sx - GAP - PW
	var right_sx  := center_sx + CW + GAP

	# ---- 4. 面板组 clamp 到屏幕内（只移面板组，不动 BattleBar） ----
	var panel_shift: int = 0
	if has_panels:
		var pg_min := center_sx
		var pg_max := center_sx + CW
		if left_panel.visible:
			pg_min = mini(pg_min, left_sx)
		if right_panel.visible:
			pg_max = maxi(pg_max, right_sx + PW)

		if pg_min < screen_min_x:
			panel_shift = screen_min_x - pg_min
		elif pg_max > screen_max_x:
			panel_shift = screen_max_x - pg_max

	var center_ssx := center_sx + panel_shift
	var left_ssx   := left_sx   + panel_shift
	var right_ssx  := right_sx  + panel_shift

	# ---- 5. Window origin = virtual frame（不以 union rect 决定） ----
	var win_x := bb_sx - BATTLE_REST_X
	var win_y: int
	if has_panels and flipped:
		win_y = bb_sy
	else:
		win_y = bb_sy - FLIP_BOT

	var screen_win_min_x := screen.position.x + EDGE_MARGIN
	var screen_win_max_x := screen.position.x + screen.size.x - WIN_W - EDGE_MARGIN
	if screen_win_max_x >= screen_win_min_x:
		win_x = clampi(win_x, screen_win_min_x, screen_win_max_x)

	win.position = Vector2i(win_x, win_y)

	# ---- 6. local = screen - window ----
	battle_bar.position = Vector2i(bb_sx - win_x, bb_sy - win_y)

	if has_panels:
		center_panel.position = Vector2i(center_ssx - win_x, panel_sy - win_y)
		if left_panel.visible:
			left_panel.position = Vector2i(left_ssx - win_x, panel_sy - win_y)
		if right_panel.visible:
			right_panel.position = Vector2i(right_ssx - win_x, panel_sy - win_y)

	# ---- 7. 日志节流 ----
	var log_reason := ""
	if _last_log_mode != _current_mode:
		log_reason = "mode"
		_last_log_mode = _current_mode
	elif _last_log_flipped != flipped:
		log_reason = "flip"
		_last_log_flipped = flipped
	elif _last_log_shift != panel_shift:
		log_reason = "shift"
		_last_log_shift = panel_shift
	elif not _dragging:
		log_reason = "idle"
	elif _log_frame_count % LOG_THROTTLE == 0:
		log_reason = "throttle"
	_log_frame_count += 1

	if log_reason != "":
		var pg_x1 := center_ssx
		var pg_x2 := center_ssx + CW
		if left_panel.visible:
			pg_x1 = mini(pg_x1, left_ssx)
			pg_x2 = maxi(pg_x2, left_ssx + PW)
		if right_panel.visible:
			pg_x1 = mini(pg_x1, right_ssx)
			pg_x2 = maxi(pg_x2, right_ssx + PW)

		print("[roguefall] --- layout ---  reason=%s  mode=%d  battle_screen=(%d,%d,%d,%d)  pg_screen=(%d,%d,%d,%d)  shift=%d  window=(%d,%d)  battle_local=(%d,%d)  center_local=(%d,%d)  flipped=%s" % [
			log_reason, _current_mode,
			bb_sx, bb_sy, bb_sw, bb_sh,
			pg_x1 if has_panels else -1, panel_sy if has_panels else -1,
			pg_x2 if has_panels else -1, (panel_sy + PANEL_H) if has_panels else -1,
			panel_shift,
			win_x, win_y,
			battle_bar.position.x, battle_bar.position.y,
			center_panel.position.x if center_panel.visible else -1,
			center_panel.position.y if center_panel.visible else -1,
			flipped
		])


# ===== 穿透 =====
func _update_passthrough() -> void:
	pass  # 穿透暂时废除，等 BattleBar / 三栏布局稳定后再接入


# ===== 拖拽：屏幕坐标 + 每帧 _do_layout =====
func start_drag() -> void:
	_dragging = true
	var mouse_screen := Vector2i(DisplayServer.mouse_get_position())
	_drag_offset_x = _battle_anchor_screen_x - mouse_screen.x
	_drag_offset_y = _battle_anchor_screen_y - mouse_screen.y


func end_drag() -> void:
	_dragging = false

	_save_position()
	_do_layout()
	_update_passthrough()


func _process(_delta: float) -> void:
	if not _dragging:
		return

	var mouse_screen := Vector2i(DisplayServer.mouse_get_position())
	var win := get_window()
	var screen := DisplayServer.screen_get_usable_rect(win.current_screen)

	# 锚点 = 鼠标屏幕坐标 + 固定偏移
	var ax := mouse_screen.x + _drag_offset_x
	var ay := mouse_screen.y + _drag_offset_y

	# 只 clamp BattleBar 自身屏幕矩形
	ax = clampi(ax, screen.position.x + EDGE_MARGIN, screen.position.x + screen.size.x - int(battle_bar.size.x) - EDGE_MARGIN)
	ay = clampi(ay, screen.position.y + EDGE_MARGIN, screen.position.y + screen.size.y - BATTLE_H - EDGE_MARGIN)

	_battle_anchor_screen_x = ax
	_battle_anchor_screen_y = ay

	# 每帧调用 _do_layout 保持落点一致，不直接设 win.position
	_do_layout()


# ===== 持久化 =====
func _save_position() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("window", "anchor_x", _battle_anchor_screen_x)
	cfg.set_value("window", "anchor_y", _battle_anchor_screen_y)
	cfg.save("user://window.cfg")


func _load_position() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load("user://window.cfg") != OK:
		return false
	var ax = cfg.get_value("window", "anchor_x", null)
	var ay = cfg.get_value("window", "anchor_y", null)
	if ax == null or ay == null:
		return false
	_battle_anchor_screen_x = int(ax)
	_battle_anchor_screen_y = int(ay)
	return true


func _center_on_screen() -> void:
	var screen := DisplayServer.screen_get_usable_rect(get_window().current_screen)
	get_window().position = Vector2i(
		screen.position.x + (screen.size.x - WIN_W) / 2,
		screen.position.y + (screen.size.y - WIN_H) / 2
	)


# ===== 按钮 =====
func _on_bag() -> void:
	_apply_mode(Mode.CENTER_BATTLE if _current_mode == Mode.BATTLE_ONLY else Mode.BATTLE_ONLY)

func _on_left() -> void:
	match _current_mode:
		Mode.CENTER_BATTLE: _apply_mode(Mode.LEFT_CENTER_BATTLE)
		Mode.CENTER_RIGHT_BATTLE: _apply_mode(Mode.FULL)
		Mode.LEFT_CENTER_BATTLE: _apply_mode(Mode.CENTER_BATTLE)
		Mode.FULL: _apply_mode(Mode.CENTER_RIGHT_BATTLE)

func _on_right() -> void:
	match _current_mode:
		Mode.CENTER_BATTLE: _apply_mode(Mode.CENTER_RIGHT_BATTLE)
		Mode.LEFT_CENTER_BATTLE: _apply_mode(Mode.FULL)
		Mode.CENTER_RIGHT_BATTLE: _apply_mode(Mode.CENTER_BATTLE)
		Mode.FULL: _apply_mode(Mode.LEFT_CENTER_BATTLE)
