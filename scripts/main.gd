extends Control

const EDGE_MARGIN := 16
const GAP := 8
const BATTLE_H := 180
const PANEL_H := 530
const WIN_W := 1440
const WIN_H := 718     # 530 + 8 + 180，翻转就是上下对调
const FLIP_TOP := 0     # 战斗条在上的窗口 y 偏移（战斗条占顶部 180px）
const FLIP_BOT := 538   # 战斗条在下的窗口 y 偏移（面板区 530px + 间距 8px）
const PANEL_Y_ABOVE := 0     # 面板在战斗条上方
const PANEL_Y_BELOW := 188   # 面板在战斗条下方（180 + 8）
const PW := 352    # 左/右面板宽度
const CW := 720    # 中栏宽度

enum Mode { BATTLE_ONLY, CENTER_BATTLE, LEFT_CENTER_BATTLE, CENTER_RIGHT_BATTLE, FULL }

var _loading := true
var _current_mode := -1
var _dragging := false

# 拖拽：鼠标屏幕坐标与锚点之间的固定偏移
var _drag_offset_x := 0
var _drag_offset_y := 0

# BattleBar 屏幕坐标锚点，每次布局后从 win + battle_bar 刷新
var _battle_anchor_screen_x := 0
var _battle_anchor_screen_y := 0

# BattleBar 在窗口内的当前 x，跨模式保持（拖拽后记忆位置）
var _battle_local_x: int = 0

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
	_battle_local_x = int(battle_bar.position.x)

	_apply_mode(Mode.BATTLE_ONLY)
	_loading = false
	print("[roguefall] INIT OK  mode=%d  win=(%d,%d)  size=(%d,%d)  anchor=(%d,%d)  local_x=%d" % [
		_current_mode, win.position.x, win.position.y, win.size.x, win.size.y,
		_battle_anchor_screen_x, _battle_anchor_screen_y, _battle_local_x
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


# ===== BattleBar local_x 合法范围（当前模式） =====
func _get_bbx_range() -> Array:
	var min_bbx: int = 0
	var max_bbx: int = WIN_W - int(battle_bar.size.x)  # 720
	match _current_mode:
		Mode.LEFT_CENTER_BATTLE:
			min_bbx = PW + GAP  # 360
		Mode.CENTER_RIGHT_BATTLE:
			max_bbx = WIN_W - CW - GAP - PW  # 360
		Mode.FULL:
			min_bbx = PW + GAP      # 360
			max_bbx = WIN_W - CW - GAP - PW  # 360
	return [min_bbx, max_bbx]


# ===== 布局 =====
func _do_layout() -> void:
	var win := get_window()
	var screen := DisplayServer.screen_get_usable_rect(win.current_screen)

	# ---- 垂直（保持现有上下翻转逻辑不变） ----
	var space_above := _battle_anchor_screen_y - screen.position.y - EDGE_MARGIN
	var space_below := screen.position.y + screen.size.y - (_battle_anchor_screen_y + BATTLE_H) - EDGE_MARGIN
	var flipped := space_above < space_below

	var battle_y: int
	var panel_y: int
	if flipped:
		battle_y = 0
		panel_y = PANEL_Y_BELOW
		win.position.y = _battle_anchor_screen_y
	else:
		battle_y = FLIP_BOT
		panel_y = PANEL_Y_ABOVE
		win.position.y = _battle_anchor_screen_y - FLIP_BOT

	battle_bar.position.y = battle_y
	_battle_anchor_screen_y = win.position.y + battle_y

	# ---- 水平：优先保持 _battle_local_x，只在必要时 clamp ----
	var range := _get_bbx_range()
	var min_bbx := range[0] as int
	var max_bbx := range[1] as int

	# 当前模式 clamp _battle_local_x
	_battle_local_x = clampi(_battle_local_x, min_bbx, max_bbx)

	# 窗口定位使得 BattleBar 在窗口内位置 = _battle_local_x
	win.position.x = _battle_anchor_screen_x - _battle_local_x

	# 窗口不越屏幕
	var screen_min_x := screen.position.x + EDGE_MARGIN
	var screen_max_x := screen.position.x + screen.size.x - WIN_W - EDGE_MARGIN
	if screen_max_x >= screen_min_x:
		win.position.x = clampi(win.position.x, screen_min_x, screen_max_x)

	# 窗口 clamp 后反算 BattleBar 实际落点，并再钳位到模式范围
	var bbx := clampi(_battle_anchor_screen_x - win.position.x, min_bbx, max_bbx)
	battle_bar.position.x = bbx

	# 持久化本次落点，供下次布局保持
	_battle_local_x = bbx

	# Center / Left / Right 全部从 battle_bar.x 推导
	var cx := bbx
	var lx := cx - PW - GAP
	var rx := cx + CW + GAP

	left_panel.position = Vector2i(lx, panel_y)
	center_panel.position = Vector2i(cx, panel_y)
	right_panel.position = Vector2i(rx, panel_y)

	print("[roguefall] --- layout ---")
	print("  mode=%d  win=(%d,%d)  bb_win=(%d,%d)  bb_screen_y=%d  flipped=%s  panel_y=%d" % [
		_current_mode, win.position.x, win.position.y,
		bbx, battle_y, _battle_anchor_screen_y, flipped, panel_y
	])
	print("  L(%d,%d)  C(%d,%d)  R(%d,%d)  bbx_range=[%d,%d]" % [
		lx, panel_y, cx, panel_y, rx, panel_y, min_bbx, max_bbx
	])
	print("  anchor_screen_x=%d  battle_local_x=%d" % [
		_battle_anchor_screen_x, _battle_local_x
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
