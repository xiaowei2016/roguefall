extends Control

const ACTIVE_COLOR := Color(0.1, 0.34, 0.55, 1.0)
const INACTIVE_COLOR := Color(0.42, 0.22, 0.08, 1.0)

@onready var base_tab := $Card/Tabs/BaseTab
@onready var battle_tab := $Card/Tabs/BattleTab
@onready var loot_tab := $Card/Tabs/LootTab
@onready var base_label := $Card/Tabs/BaseTab/Label
@onready var battle_label := $Card/Tabs/BattleTab/Label
@onready var loot_label := $Card/Tabs/LootTab/Label
@onready var stats_scroll := $Card/StatsScroll
@onready var base_rows := [
	$Card/StatsScroll/Stats/BaseSectionTitle,
	$Card/StatsScroll/Stats/Stat1,
	$Card/StatsScroll/Stats/Stat2,
	$Card/StatsScroll/Stats/Stat3,
	$Card/StatsScroll/Stats/Stat4,
	$Card/StatsScroll/Stats/Stat5,
]
@onready var battle_rows := [
	$Card/StatsScroll/Stats/BattleSectionTitle,
	$Card/StatsScroll/Stats/Stat6,
	$Card/StatsScroll/Stats/Stat7,
	$Card/StatsScroll/Stats/Stat8,
	$Card/StatsScroll/Stats/Stat9,
]
@onready var loot_rows := [
	$Card/StatsScroll/Stats/LootSectionTitle,
	$Card/StatsScroll/Stats/Stat10,
	$Card/StatsScroll/Stats/Stat11,
	$Card/StatsScroll/Stats/Stat12,
]

var _active_style: StyleBox
var _inactive_style: StyleBox


func _ready() -> void:
	_active_style = base_tab.get_theme_stylebox("panel")
	_inactive_style = battle_tab.get_theme_stylebox("panel")
	base_tab.gui_input.connect(func(event: InputEvent) -> void: _on_tab_input(event, 0))
	battle_tab.gui_input.connect(func(event: InputEvent) -> void: _on_tab_input(event, 1))
	loot_tab.gui_input.connect(func(event: InputEvent) -> void: _on_tab_input(event, 2))
	select_group(0)


func select_group(group_index: int) -> void:
	_set_rows_visible(base_rows, group_index == 0)
	_set_rows_visible(battle_rows, group_index == 1)
	_set_rows_visible(loot_rows, group_index == 2)
	_set_tab_state(base_tab, base_label, group_index == 0)
	_set_tab_state(battle_tab, battle_label, group_index == 1)
	_set_tab_state(loot_tab, loot_label, group_index == 2)
	stats_scroll.scroll_vertical = 0


func _on_tab_input(event: InputEvent, group_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		select_group(group_index)


func _set_rows_visible(rows: Array, is_visible: bool) -> void:
	for row in rows:
		row.visible = is_visible


func _set_tab_state(tab: Panel, label: Label, is_active: bool) -> void:
	tab.add_theme_stylebox_override("panel", _active_style if is_active else _inactive_style)
	label.add_theme_color_override("font_color", ACTIVE_COLOR if is_active else INACTIVE_COLOR)
