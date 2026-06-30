extends Control

const TOOLTIP_SIZE := Vector2(228, 300)
const EQUIPPED_TOOLTIP_SIZE := Vector2(218, 220)
const TOOLTIP_GAP := 8.0
const HOVER_DELAY := 1.0
const SLOT_HOVER_BG := Color(1.0, 0.95, 0.78, 1.0)
const SLOT_HOVER_BORDER := Color(1.0, 0.72, 0.22, 1.0)
const SLOT_LOCKED_BG := Color(1.0, 0.9, 0.58, 1.0)
const SLOT_LOCKED_BORDER := Color(0.95, 0.42, 0.08, 1.0)
const EQUIPMENT_KINDS := ["武器", "头部", "身体", "项链", "戒指", "腰带", "脚部", "手部", "护符"]
const CONSUMABLE_KINDS := ["消耗品", "宝箱", "宠物道具"]
const EQUIPPED_SLOT_NAMES := [
	"SlotLeft1",
	"SlotLeft2",
	"SlotLeft3",
	"SlotRight1",
	"SlotRight2",
	"SlotRight3",
	"SlotBottom1",
	"SlotBottom2",
	"SlotBottom3",
]
const EQUIPMENT_SLOT_BY_KIND := {
	"武器": "SlotLeft1",
	"头部": "SlotLeft2",
	"身体": "SlotLeft3",
	"项链": "SlotRight1",
	"戒指": "SlotRight2",
	"腰带": "SlotRight3",
	"脚部": "SlotBottom1",
	"手部": "SlotBottom2",
	"护符": "SlotBottom3",
}
const BAG_SLOT_PREFIX := "BagSlot"
const BAG_SLOT_COUNT := 25

@onready var power_label: Label = $HeroCard/PowerPanel/PowerLabel
@onready var atk_label: Label = $HeroCard/StatsScroll/StatList/AtkLabel
@onready var def_label: Label = $HeroCard/StatsScroll/StatList/DefLabel
@onready var hp_label: Label = $HeroCard/StatsScroll/StatList/HpLabel
@onready var level_label: Label = $HeroCard/LevelLabel
@onready var item_tooltip: Panel = $ItemTooltip
@onready var tip_title: Label = $ItemTooltip/TitleLabel
@onready var tip_type: Label = $ItemTooltip/TypeLabel
@onready var tip_rarity: Label = $ItemTooltip/RarityLabel
@onready var tip_power: Label = $ItemTooltip/PowerLabel
@onready var tip_base: Label = $ItemTooltip/BaseLabel
@onready var tip_affix_1: Label = $ItemTooltip/Affix1
@onready var tip_affix_2: Label = $ItemTooltip/Affix2
@onready var tip_affix_3: Label = $ItemTooltip/Affix3
@onready var tip_desc: Label = $ItemTooltip/DescLabel
@onready var tip_compare: Label = $ItemTooltip/CompareLabel
@onready var tip_action_button: Button = $ItemTooltip/ActionButton
@onready var equipped_tooltip: Panel = $EquippedTooltip
@onready var equipped_name: Label = $EquippedTooltip/NameLabel
@onready var equipped_kind: Label = $EquippedTooltip/KindLabel
@onready var equipped_power: Label = $EquippedTooltip/PowerLabel
@onready var equipped_base: Label = $EquippedTooltip/BaseLabel
@onready var equipped_affix: Label = $EquippedTooltip/AffixLabel
@onready var bag_filter_all: Button = $BagPanel/Tabs/AllTab
@onready var bag_filter_equip: Button = $BagPanel/Tabs/EquipTab
@onready var bag_filter_consumable: Button = $BagPanel/Tabs/ConsumableTab
@onready var bag_filter_other: Button = $BagPanel/Tabs/OtherTab
@onready var bag_capacity_label: Label = $BagPanel/CapacityLabel
@onready var bag_sort_button: Button = $BagPanel/SortButton
@onready var bag_use_button: Button = $BagPanel/UseButton

var _tooltip_locked := false
var _hovered_slot: Control
var _hover_token := 0
var _slot_default_styles := {}
var _current_item := {}
var _current_slot: Control
var _bag_filter := "all"
var _show_equipped_compare := false
var _slot_items := {
	"SlotLeft1": {
		"name": "新手长剑",
		"kind": "武器",
		"rarity": "稀有",
		"power": "战力 +120",
		"base": "基础：攻击 +10",
		"affixes": ["暴击 +1%", "金币 +2%", "洗练槽 2 / 4"],
		"desc": "装备结构：主属性 + 随机词条 + 洗练槽。适合前期挂机。"
	},
	"SlotLeft2": {
		"name": "冒险头盔",
		"kind": "头部",
		"rarity": "普通",
		"power": "战力 +60",
		"base": "基础：生命 +30",
		"affixes": ["防御 +2", "生命恢复 +1"],
		"desc": "装备结构：防具主属性偏生存。"
	},
	"SlotLeft3": {
		"name": "旅人胸甲",
		"kind": "身体",
		"rarity": "普通",
		"power": "战力 +85",
		"base": "基础：防御 +5",
		"affixes": ["生命 +20", "减伤 +1%"],
		"desc": "装备结构：防御主属性 + 生存词条。"
	},
	"SlotRight1": {
		"name": "星纹项链",
		"kind": "项链",
		"rarity": "精良",
		"power": "战力 +95",
		"base": "基础：幸运 +2",
		"affixes": ["掉落 +2%", "经验 +1%"],
		"desc": "饰品更适合做收益和特殊词条。"
	},
	"SlotRight2": {
		"name": "紫晶戒指",
		"kind": "戒指",
		"rarity": "精良",
		"power": "战力 +110",
		"base": "基础：暴击 +2%",
		"affixes": ["攻击 +4", "暴伤 +8%"],
		"desc": "戒指结构：战斗词条优先。"
	},
	"SlotRight3": {
		"name": "皮革腰带",
		"kind": "腰带",
		"rarity": "普通",
		"power": "战力 +55",
		"base": "基础：生命 +25",
		"affixes": ["背包容量 +2"],
		"desc": "腰带可以承载容量、生命等功能词条。"
	},
	"SlotBottom1": {
		"name": "疾行靴",
		"kind": "脚部",
		"rarity": "普通",
		"power": "战力 +70",
		"base": "基础：敏捷 +3",
		"affixes": ["攻速 +1%", "移动 +2%"],
		"desc": "底部三格用于鞋、护手、副手等装备。"
	},
	"SlotBottom2": {
		"name": "练习护手",
		"kind": "手部",
		"rarity": "普通",
		"power": "战力 +50",
		"base": "基础：攻击 +3",
		"affixes": ["命中 +1%"],
		"desc": "护手适合攻击和命中类词条。"
	},
	"SlotBottom3": {
		"name": "木制护符",
		"kind": "护符",
		"rarity": "稀有",
		"power": "战力 +100",
		"base": "基础：幸运 +4",
		"affixes": ["金币 +3%", "掉落 +1%"],
		"desc": "护符结构偏收益，是挂机玩法的关键位。"
	},
	"BagSlot1": {
		"name": "紫晶碎片",
		"kind": "材料",
		"rarity": "稀有",
		"power": "堆叠 12",
		"base": "用途：装备洗练",
		"affixes": ["来源：彩虹草原", "品质：紫色材料"],
		"desc": "材料弹窗也用同一结构，后续可接入真实物品库。"
	},
	"BagSlot2": {
		"name": "铁质短剑",
		"kind": "武器",
		"rarity": "精良",
		"power": "战力 +145",
		"base": "基础：攻击 +13",
		"affixes": ["暴击 +2%", "命中 +1%", "洗练槽 1 / 4"],
		"desc": "背包里的装备会和同类型已装备物品对比。"
	},
	"BagSlot3": {
		"name": "齿轮核心",
		"kind": "材料",
		"rarity": "普通",
		"power": "堆叠 3",
		"base": "用途：装备强化",
		"affixes": ["来源：小怪掉落"],
		"desc": "普通材料用于强化基础装备。"
	},
	"BagSlot4": {
		"name": "宠物点心",
		"kind": "宠物",
		"rarity": "普通",
		"power": "堆叠 6",
		"base": "效果：亲密度 +5",
		"affixes": ["宠物页可查看亲密度"],
		"desc": "用于后续宠物系统。"
	},
	"BagSlot5": {
		"name": "草原地图",
		"kind": "任务",
		"rarity": "普通",
		"power": "堆叠 9",
		"base": "效果：探索进度",
		"affixes": ["区域：彩虹草原"],
		"desc": "可在地图页扩展路线节点。"
	},
	"BagSlot6": {
		"name": "旧木箱",
		"kind": "宝箱",
		"rarity": "普通",
		"power": "堆叠 2",
		"base": "效果：打开获得奖励",
		"affixes": ["可能掉落装备", "可能掉落金币"],
		"desc": "宝箱可复用装备弹窗展示奖励预览。"
	},
}


func _ready() -> void:
	_setup_item_slots()
	_setup_filter_tabs()
	_capture_initial_slot_visuals()
	_refresh_all_slot_visuals()
	_update_bag_capacity()
	bag_sort_button.pressed.connect(_on_bag_sort_pressed)
	bag_use_button.pressed.connect(_on_bag_use_pressed)
	tip_action_button.pressed.connect(_on_tip_action_pressed)
	item_tooltip.visible = false
	equipped_tooltip.visible = false


func refresh_from_game_data(data: Node) -> void:
	var power := int(data.attack) * 80 + int(data.defense) * 60 + int(data.max_hp) * 2
	level_label.text = "Lv." + str(data.level)
	power_label.text = "战力 " + _format_number(power)
	atk_label.text = "攻击 " + str(data.attack)
	def_label.text = "防御 " + str(data.defense)
	hp_label.text = "生命 " + str(data.hp) + " / " + str(data.max_hp)


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


func _setup_item_slots() -> void:
	for slot_name in _get_all_slot_names():
		var slot := _find_slot(slot_name)
		if slot == null:
			continue
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		_remember_slot_style(slot)
		slot.mouse_entered.connect(func() -> void: _on_slot_mouse_entered(slot))
		slot.mouse_exited.connect(func() -> void: _hide_item_tip(slot))
		slot.gui_input.connect(func(event: InputEvent) -> void: _on_slot_gui_input(event, slot))
		_set_children_ignore_mouse(slot)


func _get_all_slot_names() -> Array:
	var names := []
	names.append_array(EQUIPPED_SLOT_NAMES)
	for index in range(1, BAG_SLOT_COUNT + 1):
		names.append(BAG_SLOT_PREFIX + str(index))
	return names


func _capture_initial_slot_visuals() -> void:
	for slot_name in _slot_items.keys():
		var item: Dictionary = _slot_items[slot_name]
		var slot := _find_slot(slot_name)
		if slot == null:
			continue
		var icon := _get_or_create_icon(slot, false)
		if icon != null and icon.texture != null:
			item["icon_texture"] = icon.texture
		var count_label := slot.get_node_or_null("Count") as Label
		if count_label != null and count_label.text.strip_edges() != "":
			item["count"] = count_label.text


func _setup_filter_tabs() -> void:
	bag_filter_all.pressed.connect(func() -> void: _set_bag_filter("all"))
	bag_filter_equip.pressed.connect(func() -> void: _set_bag_filter("equip"))
	bag_filter_consumable.pressed.connect(func() -> void: _set_bag_filter("consumable"))
	bag_filter_other.pressed.connect(func() -> void: _set_bag_filter("other"))
	_set_bag_filter("all")


func _set_bag_filter(filter_name: String) -> void:
	_bag_filter = filter_name
	_close_item_tip()
	_apply_bag_filter_visibility()
	_update_filter_buttons()
	_refresh_all_slot_visuals()


func _apply_bag_filter_visibility() -> void:
	for child in $BagPanel/BagScroll/BagGrid.get_children():
		if child is Control:
			var slot := child as Control
			var item: Dictionary = _slot_items.get(slot.name, {})
			slot.visible = item.is_empty() or _item_matches_filter(item, _bag_filter)


func _item_matches_filter(item: Dictionary, filter_name: String) -> bool:
	if filter_name == "all":
		return true
	var kind := str(item.get("kind", ""))
	if filter_name == "equip":
		return EQUIPMENT_KINDS.has(kind)
	if filter_name == "consumable":
		return CONSUMABLE_KINDS.has(kind)
	if filter_name == "other":
		return not EQUIPMENT_KINDS.has(kind) and not CONSUMABLE_KINDS.has(kind)
	return true


func _update_filter_buttons() -> void:
	var buttons := {
		"all": bag_filter_all,
		"equip": bag_filter_equip,
		"consumable": bag_filter_consumable,
		"other": bag_filter_other,
	}
	for key in buttons.keys():
		var button: Button = buttons[key]
		button.disabled = key == _bag_filter


func _on_bag_sort_pressed() -> void:
	_close_item_tip()
	_sort_bag_items()
	_apply_bag_filter_visibility()
	_update_filter_buttons()
	_refresh_all_slot_visuals()
	_update_bag_capacity()


func _on_bag_use_pressed() -> void:
	var slot_name := _get_quick_use_slot_name()
	if slot_name == "":
		_close_item_tip()
		return
	var item: Dictionary = _slot_items.get(slot_name, {})
	if item.is_empty():
		return
	_use_bag_item(slot_name, item)


func _get_quick_use_slot_name() -> String:
	if _current_slot != null:
		var current_item: Dictionary = _slot_items.get(_current_slot.name, {})
		if _is_usable_item(current_item):
			return _current_slot.name
	for slot_name in _get_bag_slot_names():
		var item: Dictionary = _slot_items.get(slot_name, {})
		if _is_usable_item(item):
			return slot_name
	return ""


func _is_usable_item(item: Dictionary) -> bool:
	if item.is_empty():
		return false
	return CONSUMABLE_KINDS.has(str(item.get("kind", "")))


func _use_bag_item(slot_name: String, item: Dictionary) -> void:
	var remaining := _item_count(item) - 1
	var used_name := str(item.get("name", "物品"))
	if remaining > 0:
		item["count"] = str(remaining)
		if str(item.get("power", "")).begins_with("堆叠"):
			item["power"] = "堆叠 " + str(remaining)
		_slot_items[slot_name] = item
	else:
		_slot_items.erase(slot_name)
	_refresh_all_slot_visuals()
	_update_bag_capacity()
	_apply_bag_filter_visibility()
	_update_filter_buttons()
	if remaining > 0:
		_close_item_tip()
		var slot := _find_slot(slot_name)
		if slot != null:
			_show_item_tip(slot, true)
			tip_compare.visible = true
			tip_compare.text = "已使用：" + used_name + "\n剩余：" + str(remaining)
	else:
		_current_item = {}
		_current_slot = null
		tip_action_button.text = "已使用"
		tip_action_button.disabled = true
		tip_compare.visible = true
		tip_compare.text = "已使用：" + used_name + "\n该格已清空"


func _item_count(item: Dictionary) -> int:
	var count_text := str(item.get("count", ""))
	var value := int(count_text) if count_text != "" else _extract_power(item.get("power", ""))
	return maxi(value, 1)


func _sort_bag_items() -> void:
	var slot_names := _get_bag_slot_names()
	var items := []
	for slot_name in slot_names:
		var item: Dictionary = _slot_items.get(slot_name, {})
		if not item.is_empty():
			items.append(item.duplicate(true))
	items.sort_custom(_is_bag_item_before)
	for slot_name in slot_names:
		_slot_items.erase(slot_name)
	for index in items.size():
		if index < slot_names.size():
			_slot_items[slot_names[index]] = items[index]


func _get_bag_slot_names() -> Array:
	var names := []
	for index in range(1, BAG_SLOT_COUNT + 1):
		names.append(BAG_SLOT_PREFIX + str(index))
	return names


func _is_bag_item_before(a: Dictionary, b: Dictionary) -> bool:
	var group_a := _item_sort_group(a)
	var group_b := _item_sort_group(b)
	if group_a != group_b:
		return group_a < group_b
	var kind_a := str(a.get("kind", ""))
	var kind_b := str(b.get("kind", ""))
	if kind_a != kind_b:
		return kind_a < kind_b
	var rarity_a := _rarity_rank(str(a.get("rarity", "")))
	var rarity_b := _rarity_rank(str(b.get("rarity", "")))
	if rarity_a != rarity_b:
		return rarity_a > rarity_b
	var power_a := _extract_power(a.get("power", ""))
	var power_b := _extract_power(b.get("power", ""))
	if power_a != power_b:
		return power_a > power_b
	return str(a.get("name", "")) < str(b.get("name", ""))


func _item_sort_group(item: Dictionary) -> int:
	var kind := str(item.get("kind", ""))
	if EQUIPMENT_KINDS.has(kind):
		return 0
	if CONSUMABLE_KINDS.has(kind):
		return 1
	if kind == "材料":
		return 2
	return 3


func _rarity_rank(rarity: String) -> int:
	if rarity == "传说":
		return 5
	if rarity == "史诗":
		return 4
	if rarity == "稀有":
		return 3
	if rarity == "精良":
		return 2
	if rarity == "普通":
		return 1
	return 0


func _update_bag_capacity() -> void:
	var used := 0
	for slot_name in _get_bag_slot_names():
		var item: Dictionary = _slot_items.get(slot_name, {})
		if not item.is_empty():
			used += 1
	bag_capacity_label.text = str(used) + "/" + str(BAG_SLOT_COUNT)


func _find_slot(slot_name: String) -> Control:
	var node := get_node_or_null("HeroCard/" + slot_name)
	if node == null:
		node = get_node_or_null("BagPanel/BagScroll/BagGrid/" + slot_name)
	return node as Control


func _set_children_ignore_mouse(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_children_ignore_mouse(child)


func _on_slot_gui_input(event: InputEvent, slot: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _tooltip_locked and _hovered_slot == slot:
			_close_item_tip()
			return
		_show_item_tip(slot, true)
		accept_event()


func _on_slot_mouse_entered(slot: Control) -> void:
	if not _tooltip_locked:
		_set_slot_visual(slot, "hover")
	_queue_item_tip(slot)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _tooltip_locked:
			_close_item_tip()


func _queue_item_tip(slot: Control) -> void:
	if _tooltip_locked:
		return
	_hovered_slot = slot
	_hover_token += 1
	var token := _hover_token
	await get_tree().create_timer(HOVER_DELAY).timeout
	if _tooltip_locked:
		return
	if token == _hover_token and _hovered_slot == slot and slot.get_global_rect().has_point(get_global_mouse_position()):
		_show_item_tip(slot, false)


func _show_item_tip(slot: Control, lock_tip: bool) -> void:
	if _tooltip_locked and not lock_tip:
		return
	var item = _slot_items.get(slot.name, null)
	if item == null:
		return
	if lock_tip and _hovered_slot != null and _hovered_slot != slot:
		_set_slot_visual(_hovered_slot, "normal")
	_hovered_slot = slot
	_tooltip_locked = lock_tip
	_set_slot_visual(slot, "locked" if lock_tip else "hover")
	_current_item = item
	_current_slot = slot
	_fill_item_tip(item, slot)
	_position_item_tips(slot)
	item_tooltip.visible = true


func _hide_item_tip(slot: Control) -> void:
	if _tooltip_locked:
		return
	if _hovered_slot == slot:
		_hover_token += 1
		_close_item_tip()
	else:
		_set_slot_visual(slot, "normal")


func _remember_slot_style(slot: Control) -> void:
	var style := slot.get_theme_stylebox("panel")
	if style != null:
		_slot_default_styles[slot.get_instance_id()] = style.duplicate()


func _set_slot_visual(slot: Control, state: String) -> void:
	if slot == null:
		return
	var base_style: StyleBox = _slot_default_styles.get(slot.get_instance_id(), null)
	if base_style == null:
		return
	var next_style := base_style.duplicate()
	if next_style is StyleBoxFlat:
		var flat := next_style as StyleBoxFlat
		if state == "hover":
			flat.bg_color = SLOT_HOVER_BG
			flat.border_color = SLOT_HOVER_BORDER
		elif state == "locked":
			flat.bg_color = SLOT_LOCKED_BG
			flat.border_color = SLOT_LOCKED_BORDER
	slot.add_theme_stylebox_override("panel", next_style)


func _fill_item_tip(item: Dictionary, slot: Control) -> void:
	tip_title.text = item.get("name", "未知物品")
	tip_type.text = item.get("kind", "物品")
	tip_rarity.text = item.get("rarity", "普通")
	tip_power.text = item.get("power", "")
	tip_base.text = item.get("base", "")
	var affixes: Array = item.get("affixes", [])
	var affix_labels := [tip_affix_1, tip_affix_2, tip_affix_3]
	for index in affix_labels.size():
		var label: Label = affix_labels[index]
		if index < affixes.size():
			label.visible = true
			label.text = "词条：" + str(affixes[index])
		else:
			label.visible = false
	tip_desc.text = item.get("desc", "点击格子可锁定详情")
	_fill_equip_action(item, slot)


func _fill_equip_action(item: Dictionary, slot: Control) -> void:
	var kind := str(item.get("kind", ""))
	var is_equipment := EQUIPMENT_KINDS.has(kind)
	tip_compare.visible = false
	equipped_tooltip.visible = false
	_show_equipped_compare = false
	tip_action_button.visible = true
	if not is_equipment:
		if _is_usable_item(item):
			tip_action_button.text = "使用"
			tip_action_button.disabled = false
			tip_compare.visible = true
			tip_compare.text = "操作：点击下方按钮使用"
		else:
			tip_action_button.text = "存入"
			tip_action_button.disabled = not slot.name.begins_with(BAG_SLOT_PREFIX)
			tip_compare.visible = true
			tip_compare.text = "操作：点击下方按钮存入仓库"
		return
	var is_equipped_slot := EQUIPPED_SLOT_NAMES.has(slot.name)
	tip_action_button.disabled = false
	tip_action_button.text = "卸下" if is_equipped_slot else "装备"
	var equipped_item := _get_equipped_item(kind)
	if is_equipped_slot:
		tip_compare.visible = true
		tip_compare.text = "状态：已装备\n操作：点击下方按钮卸下到背包"
	elif equipped_item.is_empty():
		tip_compare.visible = true
		tip_compare.text = "已装备：无"
	else:
		_fill_equipped_tip(equipped_item)
		_show_equipped_compare = true


func _get_equipped_item(kind: String) -> Dictionary:
	return _slot_items.get(_get_equipped_slot_name(kind), {})


func _extract_power(value) -> int:
	var text := str(value)
	var digits := ""
	for index in text.length():
		var ch := text[index]
		if ch >= "0" and ch <= "9":
			digits += ch
	return int(digits) if digits != "" else 0


func _format_delta(delta: int) -> String:
	if delta > 0:
		return "+" + str(delta)
	return str(delta)


func _fill_equipped_tip(item: Dictionary) -> void:
	equipped_name.text = str(item.get("name", "未知装备"))
	equipped_kind.text = str(item.get("kind", "装备"))
	equipped_power.text = str(item.get("power", ""))
	equipped_base.text = str(item.get("base", ""))
	equipped_affix.visible = true
	equipped_affix.text = _format_affix_lines(item.get("affixes", []))


func _format_affix_lines(affixes: Array) -> String:
	if affixes.is_empty():
		return "词条：无"
	var lines := []
	for affix in affixes:
		lines.append("词条：" + str(affix))
	return "\n".join(lines)


func _on_tip_action_pressed() -> void:
	if _current_slot == null or _current_item.is_empty():
		return
	var kind := str(_current_item.get("kind", ""))
	if _is_usable_item(_current_item):
		_use_bag_item(_current_slot.name, _current_item)
		return
	if not EQUIPMENT_KINDS.has(kind) and _current_slot.name.begins_with(BAG_SLOT_PREFIX):
		_store_current_item_to_warehouse()
		return
	if not EQUIPMENT_KINDS.has(kind):
		return
	if EQUIPPED_SLOT_NAMES.has(_current_slot.name):
		_unequip_current_item()
	else:
		_equip_current_item(kind)


func equip_external_item(item: Dictionary) -> Dictionary:
	var kind := str(item.get("kind", ""))
	var target_slot_name := _get_equipped_slot_name(kind)
	if target_slot_name == "":
		return {"ok": false, "reason": "不是可装备类型"}
	var incoming_item := item.duplicate(true)
	var old_item: Dictionary = _slot_items.get(target_slot_name, {}).duplicate(true)
	_slot_items[target_slot_name] = incoming_item
	_refresh_all_slot_visuals()
	_update_bag_capacity()
	_close_item_tip()
	var target_slot := _find_slot(target_slot_name)
	if target_slot != null:
		_show_item_tip(target_slot, true)
	return {"ok": true, "old_item": old_item}


func add_bag_item(item: Dictionary) -> Dictionary:
	var target_slot_name := _find_first_empty_bag_slot()
	if target_slot_name == "":
		return {"ok": false, "reason": "背包已满"}
	_slot_items[target_slot_name] = item.duplicate(true)
	_refresh_all_slot_visuals()
	_update_bag_capacity()
	_apply_bag_filter_visibility()
	_update_filter_buttons()
	return {"ok": true, "slot_name": target_slot_name}


func get_equipped_item_for_kind(kind: String) -> Dictionary:
	return _get_equipped_item(kind).duplicate(true)


func _store_current_item_to_warehouse() -> void:
	var warehouse_panel := _get_warehouse_panel()
	if warehouse_panel == null or not warehouse_panel.has_method("add_warehouse_item"):
		tip_compare.visible = true
		tip_compare.text = "未找到仓库，无法存入"
		return
	var source_slot_name := _current_slot.name
	var source_item: Dictionary = _slot_items.get(source_slot_name, {})
	if source_item.is_empty():
		return
	var result = warehouse_panel.call("add_warehouse_item", source_item.duplicate(true))
	if not (result is Dictionary) or not bool(result.get("ok", false)):
		tip_compare.visible = true
		tip_compare.text = str(result.get("reason", "存入失败"))
		return
	_slot_items.erase(source_slot_name)
	_refresh_all_slot_visuals()
	_update_bag_capacity()
	_apply_bag_filter_visibility()
	_update_filter_buttons()
	_current_item = {}
	_current_slot = null
	tip_action_button.text = "已存入"
	tip_action_button.disabled = true
	tip_compare.visible = true
	tip_compare.text = "已存入仓库：" + str(source_item.get("name", "物品"))


func _get_warehouse_panel() -> Node:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null
	return current_scene.get_node_or_null("PanelRoot/LeftPanel/host_warehouse")


func _equip_current_item(kind: String) -> void:
	var target_slot_name := _get_equipped_slot_name(kind)
	if target_slot_name == "":
		return
	var source_slot_name := _current_slot.name
	var source_item: Dictionary = _slot_items.get(source_slot_name, {})
	if source_item.is_empty():
		return
	var old_item: Dictionary = _slot_items.get(target_slot_name, {})
	_slot_items[target_slot_name] = source_item
	if old_item.is_empty():
		_slot_items.erase(source_slot_name)
	else:
		_slot_items[source_slot_name] = old_item
	_refresh_all_slot_visuals()
	_update_bag_capacity()
	_close_item_tip()
	var target_slot := _find_slot(target_slot_name)
	if target_slot != null:
		_show_item_tip(target_slot, true)


func _unequip_current_item() -> void:
	var target_slot_name := _find_first_empty_bag_slot()
	if target_slot_name == "":
		tip_compare.visible = true
		tip_compare.text = "背包已满，无法卸下"
		return
	var source_slot_name := _current_slot.name
	var source_item: Dictionary = _slot_items.get(source_slot_name, {})
	if source_item.is_empty():
		return
	_slot_items[target_slot_name] = source_item
	_slot_items.erase(source_slot_name)
	_refresh_all_slot_visuals()
	_update_bag_capacity()
	_close_item_tip()
	var target_slot := _find_slot(target_slot_name)
	if target_slot != null:
		_show_item_tip(target_slot, true)


func _get_equipped_slot_name(kind: String) -> String:
	return str(EQUIPMENT_SLOT_BY_KIND.get(kind, ""))


func _find_first_empty_bag_slot() -> String:
	for index in range(1, BAG_SLOT_COUNT + 1):
		var slot_name := BAG_SLOT_PREFIX + str(index)
		if not _slot_items.has(slot_name):
			return slot_name
	return ""


func _refresh_all_slot_visuals() -> void:
	for slot_name in _get_all_slot_names():
		var slot := _find_slot(slot_name)
		if slot == null:
			continue
		var item: Dictionary = _slot_items.get(slot_name, {})
		_apply_slot_item_visual(slot, item)


func _apply_slot_item_visual(slot: Control, item: Dictionary) -> void:
	var icon := _get_or_create_icon(slot, not item.is_empty())
	if icon != null:
		icon.visible = not item.is_empty() and item.has("icon_texture")
		if item.has("icon_texture"):
			icon.texture = item["icon_texture"]
	var count_label := _get_or_create_count_label(slot, item.has("count"))
	if count_label != null:
		var count_text := str(item.get("count", ""))
		count_label.visible = count_text != "" and not EQUIPMENT_KINDS.has(str(item.get("kind", "")))
		count_label.text = count_text


func _get_or_create_icon(slot: Control, create_if_missing: bool) -> TextureRect:
	var icon := slot.get_node_or_null("Icon") as TextureRect
	if icon == null and create_if_missing:
		icon = TextureRect.new()
		icon.name = "Icon"
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 7.0
		icon.offset_top = 5.0
		icon.offset_right = -7.0
		icon.offset_bottom = -8.0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.add_child(icon)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _get_or_create_count_label(slot: Control, create_if_missing: bool) -> Label:
	var count_label := slot.get_node_or_null("Count") as Label
	if count_label == null and create_if_missing:
		count_label = Label.new()
		count_label.name = "Count"
		count_label.anchor_left = 0.45
		count_label.anchor_top = 0.52
		count_label.anchor_right = 1.0
		count_label.anchor_bottom = 1.0
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.add_theme_color_override("font_color", Color(0.22, 0.15, 0.1, 1))
		slot.add_child(count_label)
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return count_label


func _position_item_tips(slot: Control) -> void:
	var slot_rect := slot.get_global_rect()
	var viewport_size := get_viewport_rect().size
	var panel_rect := (get_parent() as Control).get_global_rect() if get_parent() is Control else get_global_rect()
	var min_global := Vector2(8.0, panel_rect.position.y + 8.0)
	var max_global := Vector2(viewport_size.x - TOOLTIP_SIZE.x - 8.0, panel_rect.position.y + panel_rect.size.y - TOOLTIP_SIZE.y - 8.0)
	var right_pos := Vector2(slot_rect.position.x + slot_rect.size.x + 10.0, slot_rect.position.y - 8.0)
	var left_pos := Vector2(slot_rect.position.x - TOOLTIP_SIZE.x - 10.0, slot_rect.position.y - 8.0)
	var global_pos := right_pos
	if right_pos.x + TOOLTIP_SIZE.x > viewport_size.x - 8.0:
		global_pos.x = left_pos.x
	global_pos.x = clampf(global_pos.x, min_global.x, maxf(min_global.x, max_global.x))
	global_pos.y = clampf(global_pos.y, min_global.y, maxf(min_global.y, max_global.y))
	item_tooltip.position = global_pos - global_position
	if _show_equipped_compare:
		_position_equipped_tip(global_pos, panel_rect, viewport_size)
		equipped_tooltip.visible = true


func _position_equipped_tip(item_global_pos: Vector2, panel_rect: Rect2, viewport_size: Vector2) -> void:
	var prefer_left := item_global_pos.x - EQUIPPED_TOOLTIP_SIZE.x - TOOLTIP_GAP
	var prefer_right := item_global_pos.x + TOOLTIP_SIZE.x + TOOLTIP_GAP
	var equipped_global := Vector2(prefer_left, item_global_pos.y)
	if prefer_left < 8.0 and prefer_right + EQUIPPED_TOOLTIP_SIZE.x <= viewport_size.x - 8.0:
		equipped_global.x = prefer_right
	var min_y := panel_rect.position.y + 8.0
	var max_y := panel_rect.position.y + panel_rect.size.y - EQUIPPED_TOOLTIP_SIZE.y - 8.0
	equipped_global.x = clampf(equipped_global.x, 8.0, viewport_size.x - EQUIPPED_TOOLTIP_SIZE.x - 8.0)
	equipped_global.y = clampf(equipped_global.y, min_y, maxf(min_y, max_y))
	equipped_tooltip.position = equipped_global - global_position


func _close_item_tip() -> void:
	var slot_to_reset := _hovered_slot
	_hover_token += 1
	_tooltip_locked = false
	item_tooltip.visible = false
	equipped_tooltip.visible = false
	_hovered_slot = null
	_current_item = {}
	_current_slot = null
	_show_equipped_compare = false
	_set_slot_visual(slot_to_reset, "normal")


func close_item_tip() -> void:
	_close_item_tip()
