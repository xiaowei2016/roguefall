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
@onready var power_label: Label = $Card/PowerPanel/PowerLabel
@onready var growth_label: Label = $Card/GrowthPanel/GrowthLabel
@onready var hint_label: Label = $Card/HintLabel
@onready var stat_1: Label = $Card/StatsScroll/Stats/Stat1
@onready var stat_2: Label = $Card/StatsScroll/Stats/Stat2
@onready var stat_3: Label = $Card/StatsScroll/Stats/Stat3
@onready var stat_4: Label = $Card/StatsScroll/Stats/Stat4
@onready var stat_5: Label = $Card/StatsScroll/Stats/Stat5
@onready var stat_6: Label = $Card/StatsScroll/Stats/Stat6
@onready var stat_7: Label = $Card/StatsScroll/Stats/Stat7
@onready var stat_8: Label = $Card/StatsScroll/Stats/Stat8
@onready var stat_9: Label = $Card/StatsScroll/Stats/Stat9
@onready var stat_10: Label = $Card/StatsScroll/Stats/Stat10
@onready var stat_11: Label = $Card/StatsScroll/Stats/Stat11
@onready var stat_12: Label = $Card/StatsScroll/Stats/Stat12
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
var _current_group := 0


func _ready() -> void:
	_active_style = base_tab.get_theme_stylebox("panel")
	_inactive_style = battle_tab.get_theme_stylebox("panel")
	base_tab.gui_input.connect(func(event: InputEvent) -> void: _on_tab_input(event, 0))
	battle_tab.gui_input.connect(func(event: InputEvent) -> void: _on_tab_input(event, 1))
	loot_tab.gui_input.connect(func(event: InputEvent) -> void: _on_tab_input(event, 2))
	select_group(0)


func refresh_from_game_data(data: Node) -> void:
	var power := int(data.attack) * 80 + int(data.defense) * 60 + int(data.max_hp) * 2
	power_label.text = "战力 " + _format_number(power)
	stat_1.text = "等级：" + str(data.level)
	stat_2.text = "经验：" + str(data.exp) + " / " + str(data.next_exp)
	stat_3.text = "生命：" + str(data.hp) + " / " + str(data.max_hp)
	stat_4.text = "攻击：" + str(data.attack)
	stat_5.text = "防御：" + str(data.defense)
	stat_6.text = "暴击：0%"
	stat_7.text = "暴伤：150%"
	stat_8.text = "幸运：0"
	stat_9.text = "攻速：1.00"
	stat_10.text = "金币：" + str(data.gold)
	stat_11.text = "金币加成：0%"
	stat_12.text = "掉落加成：0%"
	growth_label.text = _growth_text(data)
	hint_label.text = _group_hint(_current_group)


func select_group(group_index: int) -> void:
	_current_group = group_index
	_set_rows_visible(base_rows, group_index == 0)
	_set_rows_visible(battle_rows, group_index == 1)
	_set_rows_visible(loot_rows, group_index == 2)
	_set_tab_state(base_tab, base_label, group_index == 0)
	_set_tab_state(battle_tab, battle_label, group_index == 1)
	_set_tab_state(loot_tab, loot_label, group_index == 2)
	hint_label.text = _group_hint(group_index)
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


func _growth_text(data: Node) -> String:
	if int(data.hp) < int(data.max_hp) / 2:
		return "成长建议：生命偏低，优先补充恢复或防御装备"
	if int(data.attack) < int(data.defense) * 2:
		return "成长建议：攻击略低，优先替换武器和戒指"
	return "成长建议：当前适合继续刷草原装备和材料"


func _group_hint(group_index: int) -> String:
	if group_index == 1:
		return "战斗页用于查看输出、生存和攻击节奏"
	if group_index == 2:
		return "收益页用于查看金币、掉落和成长效率"
	return "基础页用于查看等级、经验、生命和核心属性"


func _format_number(value: int) -> String:
	var text := str(value)
	var result := ""
	var count := 0
	for index in range(text.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = text[index] + result
		count += 1
	return result
