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
const FLIP_HYSTERESIS := 48
const LOG_THROTTLE := 15
const SHIFT_LOG_INTERVAL := 15

const BATTLE_REST_X := 360

# ---- 左右栏内容状态 ----
enum LeftContent { NONE, WAREHOUSE, PET, CODEX, MAP }
enum RightContent { NONE, SETTINGS, REROLL, DETAIL }

var _loading := true
var _dragging := false

# 拖拽：鼠标屏幕坐标与锚点之间的固定偏移
var _drag_offset_x := 0
var _drag_offset_y := 0

# BattleBar 屏幕坐标锚点，唯一拖拽真源
var _battle_anchor_screen_x := 0
var _battle_anchor_screen_y := 0

# 上下翻转滞后
var _last_flipped: bool = false

# 面板显示状态
var _center_open := false
var _left_content := LeftContent.NONE
var _right_content := RightContent.NONE

# 日志节流
var _last_log_flipped: bool = false
var _last_log_shift: int = 0
var _log_frame_count: int = 0
var _shift_log_frame: int = 0

@onready var battle_bar := $PanelRoot/BattleBar
@onready var left_panel := $PanelRoot/LeftPanel
@onready var center_panel := $PanelRoot/CenterPanel
@onready var right_panel := $PanelRoot/RightPanel
@onready var center_main_panel := $PanelRoot/CenterPanel/CenterLayoutRoot/CenterMainPanel

# ---- 内容 host ----
@onready var host_warehouse := $PanelRoot/LeftPanel/host_warehouse
@onready var host_pet := $PanelRoot/LeftPanel/host_pet
@onready var host_codex := $PanelRoot/LeftPanel/host_codex
@onready var host_map := $PanelRoot/LeftPanel/host_map

@onready var host_settings := $PanelRoot/RightPanel/host_settings
@onready var host_reroll := $PanelRoot/RightPanel/host_reroll
@onready var host_detail := $PanelRoot/RightPanel/host_detail


func _ready() -> void:
	_loading = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var win := get_window()
	win.borderless = true
	win.always_on_top = true
	win.unresizable = true
	win.transparent = true
	win.size = Vector2i(WIN_W, WIN_H)

	get_viewport().transparent_bg = true

	$PanelRoot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# BattleBar 背包按钮
	$PanelRoot/BattleBar/Button.pressed.connect(_on_bag)

	# CenterPanel 左栏按钮
	$PanelRoot/CenterPanel/CenterLayoutRoot/BottomArea/LeftButtons/WarehouseBtn.pressed.connect(func(): _on_left_button(LeftContent.WAREHOUSE))
	$PanelRoot/CenterPanel/CenterLayoutRoot/BottomArea/LeftButtons/PetBtn.pressed.connect(func(): _on_left_button(LeftContent.PET))
	$PanelRoot/CenterPanel/CenterLayoutRoot/BottomArea/LeftButtons/CodexBtn.pressed.connect(func(): _on_left_button(LeftContent.CODEX))
	$PanelRoot/CenterPanel/CenterLayoutRoot/BottomArea/LeftButtons/MapBtn.pressed.connect(func(): _on_left_button(LeftContent.MAP))

	# CenterPanel 右栏按钮
	$PanelRoot/CenterPanel/CenterLayoutRoot/BottomArea/RightButtons/SettingsBtn.pressed.connect(func(): _on_right_button(RightContent.SETTINGS))
	$PanelRoot/CenterPanel/CenterLayoutRoot/BottomArea/RightButtons/RerollBtn.pressed.connect(func(): _on_right_button(RightContent.REROLL))
	$PanelRoot/CenterPanel/CenterLayoutRoot/BottomArea/RightButtons/DetailBtn.pressed.connect(func(): _on_right_button(RightContent.DETAIL))

	battle_bar.position.y = FLIP_BOT

	if not _load_position():
		_center_on_screen()

	# 从当前窗口位置和 tscn 默认 battle_bar 位置推导初始值
	_battle_anchor_screen_x = win.position.x + int(battle_bar.position.x)
	_battle_anchor_screen_y = win.position.y + int(battle_bar.position.y)

	_apply_state()
	_loading = false
	_refresh_battle_bar()
	print("[roguefall] INIT OK  center_open=%s  left=%d  right=%d  win=(%d,%d)  size=(%d,%d)  anchor=(%d,%d)  rest_x=%d" % [
		_center_open, _left_content, _right_content,
		win.position.x, win.position.y, win.size.x, win.size.y,
		_battle_anchor_screen_x, _battle_anchor_screen_y, BATTLE_REST_X
	])


# ===== 状态机 =====
func _apply_state() -> void:
	# 面板可见性
	center_panel.visible = _center_open
	left_panel.visible = _center_open and _left_content != LeftContent.NONE
	right_panel.visible = _center_open and _right_content != RightContent.NONE

	# 左栏内容切换
	host_warehouse.visible = _left_content == LeftContent.WAREHOUSE
	host_pet.visible = _left_content == LeftContent.PET
	host_codex.visible = _left_content == LeftContent.CODEX
	host_map.visible = _left_content == LeftContent.MAP

	# 右栏内容切换
	host_settings.visible = _right_content == RightContent.SETTINGS
	host_reroll.visible = _right_content == RightContent.REROLL
	host_detail.visible = _right_content == RightContent.DETAIL

	_do_layout()
	_update_passthrough()


# ===== 布局（screen-space stateless） =====
func _do_layout() -> void:
	var win := get_window()
	var screen := DisplayServer.screen_get_usable_rect(win.current_screen)

	var screen_min_x := screen.position.x + EDGE_MARGIN
	var screen_max_x := screen.position.x + screen.size.x - EDGE_MARGIN
	var has_panels := _center_open

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

	var screen_win_min_y := screen.position.y + EDGE_MARGIN
	var screen_win_max_y := screen.position.y + screen.size.y - WIN_H - EDGE_MARGIN
	if screen_win_max_y >= screen_win_min_y:
		win_y = clampi(win_y, screen_win_min_y, screen_win_max_y)

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
	if _last_log_flipped != flipped:
		log_reason = "flip"
		_last_log_flipped = flipped
	elif _last_log_shift != panel_shift:
		var shift_to_zero: bool = _last_log_shift != 0 and panel_shift == 0
		var shift_from_zero: bool = _last_log_shift == 0 and panel_shift != 0
		var shift_boundary: bool = abs(int(panel_shift)) == 360
		if shift_to_zero or shift_from_zero or shift_boundary or _shift_log_frame >= SHIFT_LOG_INTERVAL:
			log_reason = "shift"
		_last_log_shift = panel_shift
	elif not _dragging:
		log_reason = "idle"
	elif _log_frame_count % LOG_THROTTLE == 0:
		log_reason = "throttle"
	_log_frame_count += 1
	_shift_log_frame += 1

	if log_reason != "":
		if log_reason == "shift":
			_shift_log_frame = 0
		var pg_x1 := center_ssx
		var pg_x2 := center_ssx + CW
		if left_panel.visible:
			pg_x1 = mini(pg_x1, left_ssx)
			pg_x2 = maxi(pg_x2, left_ssx + PW)
		if right_panel.visible:
			pg_x1 = mini(pg_x1, right_ssx)
			pg_x2 = maxi(pg_x2, right_ssx + PW)

		print("[roguefall] --- layout ---  reason=%s  center_open=%s  left=%d  right=%d  battle_screen=(%d,%d,%d,%d)  pg_screen=(%d,%d,%d,%d)  shift=%d  window=(%d,%d)  battle_local=(%d,%d)  center_local=(%d,%d)  flipped=%s" % [
			log_reason, _center_open, _left_content, _right_content,
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
	pass  # 像素级穿透由 DesktopPixelPassthrough.cs 逐像素处理。


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
	if _dragging:
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
	_center_open = not _center_open
	if not _center_open:
		# 关闭 CenterPanel 时同时关闭左右栏
		_left_content = LeftContent.NONE
		_right_content = RightContent.NONE
	_apply_state()

func _on_left_button(content: LeftContent) -> void:
	if not _center_open:
		return
	if _left_content == content:
		_left_content = LeftContent.NONE
	else:
		_left_content = content
	_apply_state()

func _on_right_button(content: RightContent) -> void:
	if not _center_open:
		return
	if _right_content == content:
		_right_content = RightContent.NONE
	else:
		_right_content = content
	_apply_state()


func _refresh_battle_bar() -> void:
	$PanelRoot/BattleBar/Panel/LvLabel.text = "Lv " + str(GameData.level)
	$PanelRoot/BattleBar/Panel/HpLabel.text = "HP: " + str(GameData.hp) + "/" + str(GameData.max_hp)
	$PanelRoot/BattleBar/Panel/ExpLabel.text = "EXP: " + str(GameData.exp) + "/" + str(GameData.next_exp)
	$PanelRoot/BattleBar/Panel/GoldLabel.text = "Gold: " + str(GameData.gold)
	$PanelRoot/BattleBar/Panel/HpBar.max_value = max(1, GameData.max_hp)
	$PanelRoot/BattleBar/Panel/HpBar.value = clamp(GameData.hp, 0, GameData.max_hp)
	$PanelRoot/BattleBar/Panel/ExpBar.max_value = max(1, GameData.next_exp)
	$PanelRoot/BattleBar/Panel/ExpBar.value = clamp(GameData.exp, 0, GameData.next_exp)
	center_main_panel.refresh_from_game_data(GameData)
	_refresh_detail_panel()


func _refresh_detail_panel() -> void:
	$PanelRoot/RightPanel/host_detail/Card/Stats/Stat1.text = "等级：" + str(GameData.level)
	$PanelRoot/RightPanel/host_detail/Card/Stats/Stat2.text = "攻击：" + str(GameData.attack)
	$PanelRoot/RightPanel/host_detail/Card/Stats/Stat3.text = "防御：" + str(GameData.defense)
	$PanelRoot/RightPanel/host_detail/Card/Stats/Stat4.text = "生命：" + str(GameData.hp) + " / " + str(GameData.max_hp)
	$PanelRoot/RightPanel/host_detail/Card/Stats/Stat5.text = "金币：" + str(GameData.gold)
