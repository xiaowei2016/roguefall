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
var _drag_start_mouse := Vector2i()
var _drag_start_win := Vector2i()

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

	_apply_mode(Mode.BATTLE_ONLY)
	_loading = false
	print("[roguefall] INIT OK  mode=%d  win=(%d,%d)  size=(%d,%d)" % [
		_current_mode, win.position.x, win.position.y, win.size.x, win.size.y
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


# ===== 布局 =====
func _do_layout() -> void:
	var win := get_window()
	var screen := DisplayServer.screen_get_usable_rect(win.current_screen)

	# 战斗条屏幕位置是锚点（拖拽时 battle_bar 跟随窗口一起移动了，需实时重算）
	var battle_screen_y := win.position.y + int(battle_bar.position.y)
	var battle_x := int(battle_bar.position.x)

	# 翻转判断：上面空间不够就用下面
	var space_above := battle_screen_y - screen.position.y - EDGE_MARGIN
	var space_below := screen.position.y + screen.size.y - (battle_screen_y + BATTLE_H) - EDGE_MARGIN
	var flipped := space_above < space_below

	var battle_y: int
	var panel_y: int
	if flipped:
		battle_y = 0
		panel_y = PANEL_Y_BELOW
		win.position.y = battle_screen_y
	else:
		battle_y = FLIP_BOT
		panel_y = PANEL_Y_ABOVE
		win.position.y = battle_screen_y - FLIP_BOT

	battle_bar.position.y = battle_y

	# 水平布局：CenterPanel 始终对齐 BattleBar
	var cx := battle_x
	var lx := cx - PW - GAP
	var rx := cx + CW + GAP

	# 可见面板溢出窗口时，挪窗口归位（不改变面板间相对关系）
	if left_panel.visible and lx < 0:
		win.position.x -= lx
	if right_panel.visible and rx + PW > WIN_W:
		win.position.x -= (rx + PW - WIN_W)

	# 窗口不越屏幕（usable_rect 过小时跳过 clamp）
	var min_x := screen.position.x + EDGE_MARGIN
	var max_x := screen.position.x + screen.size.x - WIN_W - EDGE_MARGIN
	var min_y := screen.position.y + EDGE_MARGIN
	var max_y := screen.position.y + screen.size.y - WIN_H - EDGE_MARGIN
	if max_x >= min_x:
		win.position.x = clampi(win.position.x, min_x, max_x)
	if max_y >= min_y:
		win.position.y = clampi(win.position.y, min_y, max_y)

	left_panel.position = Vector2i(lx, panel_y)
	center_panel.position = Vector2i(cx, panel_y)
	right_panel.position = Vector2i(rx, panel_y)

	print("[roguefall] --- layout ---")
	print("  mode=%d  win=(%d,%d)  bb_win=(%d,%d)  bb_screen_y=%d  flipped=%s  panel_y=%d" % [
		_current_mode, win.position.x, win.position.y,
		battle_x, battle_y, battle_screen_y, flipped, panel_y
	])
	print("  L(%d,%d)  C(%d,%d)  R(%d,%d)" % [
		lx, panel_y, cx, panel_y, rx, panel_y
	])


# ===== 穿透 =====
func _update_passthrough() -> void:
	pass  # 穿透暂时废除，等 BattleBar / 三栏布局稳定后再接入


# ===== 拖拽 =====
func start_drag() -> void:
	_dragging = true
	_drag_start_mouse = Vector2i(DisplayServer.mouse_get_position())
	_drag_start_win = get_window().position


func end_drag() -> void:
	_dragging = false
	_save_position()
	_do_layout()
	_update_passthrough()


func _process(_delta: float) -> void:
	if not _dragging:
		return
	var delta := Vector2i(DisplayServer.mouse_get_position()) - _drag_start_mouse
	var pos := _drag_start_win + delta

	var win := get_window()
	var screen := DisplayServer.screen_get_usable_rect(win.current_screen)

	# Clamp BattleBar 屏幕矩形，窗口可局部出屏
	var bb_x := int(battle_bar.position.x)
	var bb_y := int(battle_bar.position.y)
	var bsx := pos.x + bb_x
	var bsy := pos.y + bb_y
	bsx = clampi(bsx, screen.position.x + EDGE_MARGIN, screen.position.x + screen.size.x - battle_bar.size.x - EDGE_MARGIN)
	bsy = clampi(bsy, screen.position.y + EDGE_MARGIN, screen.position.y + screen.size.y - BATTLE_H - EDGE_MARGIN)

	win.position = Vector2i(bsx - bb_x, bsy - bb_y)


# ===== 持久化 =====
func _save_position() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("window", "x", get_window().position.x)
	cfg.set_value("window", "y", get_window().position.y)
	cfg.save("user://window.cfg")


func _load_position() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load("user://window.cfg") != OK:
		return false
	var wx = cfg.get_value("window", "x", null)
	var wy = cfg.get_value("window", "y", null)
	if wx == null or wy == null:
		return false
	get_window().position = Vector2i(int(wx), int(wy))
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
