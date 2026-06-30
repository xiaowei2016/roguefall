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
@onready var filter_all: Button = $Card/FilterTabs/AllTab
@onready var filter_equip: Button = $Card/FilterTabs/EquipTab
@onready var filter_consumable: Button = $Card/FilterTabs/ConsumableTab
@onready var filter_other: Button = $Card/FilterTabs/OtherTab
@onready var sort_button: Button = $Card/SortButton
@onready var hint_label: Label = $Card/Hint

var _tooltip_locked := false
var _hovered_slot: Control
var _hover_token := 0
var _slot_default_styles := {}
var _current_item := {}
var _current_slot: Control
var _warehouse_filter := "all"
var _show_equipped_compare := false
var _equipped_items := {
	"武器": {"name": "新手长剑", "power": "战力 +120", "base": "基础：攻击 +10"},
	"身体": {"name": "旅人胸甲", "power": "战力 +85", "base": "基础：防御 +5"},
	"头部": {"name": "冒险头盔", "power": "战力 +60", "base": "基础：生命 +30"},
	"项链": {"name": "星纹项链", "power": "战力 +95", "base": "基础：幸运 +2"},
	"戒指": {"name": "紫晶戒指", "power": "战力 +110", "base": "基础：暴击 +2%"},
	"腰带": {"name": "皮革腰带", "power": "战力 +55", "base": "基础：生命 +25"},
	"脚部": {"name": "疾行靴", "power": "战力 +70", "base": "基础：敏捷 +3"},
	"手部": {"name": "练习护手", "power": "战力 +50", "base": "基础：攻击 +3"},
	"护符": {"name": "木制护符", "power": "战力 +100", "base": "基础：幸运 +4"},
}
var _slot_items := {
	"Slot1": {
		"name": "备用长剑",
		"kind": "武器",
		"rarity": "普通",
		"power": "战力 +80",
		"base": "基础：攻击 +7",
		"affixes": ["暴击 +1%", "洗练槽 1 / 4"],
		"desc": "仓库中的装备也必须能查看结构，方便和身上装备比较。"
	},
	"Slot2": {
		"name": "旧胸甲",
		"kind": "身体",
		"rarity": "普通",
		"power": "战力 +65",
		"base": "基础：防御 +4",
		"affixes": ["生命 +18", "减伤 +1%"],
		"desc": "备用防具，后续可接入换装逻辑。"
	},
	"Slot3": {
		"name": "蓝晶石",
		"kind": "材料",
		"rarity": "精良",
		"power": "堆叠 8",
		"base": "用途：强化装备",
		"affixes": ["来源：草原掉落"],
		"desc": "材料也用同一弹窗结构，只是字段显示为用途和来源。"
	},
	"Slot4": {
		"name": "宠物铃铛",
		"kind": "宠物道具",
		"rarity": "稀有",
		"power": "堆叠 2",
		"base": "效果：召回宠物",
		"affixes": ["亲密度 +3", "宠物经验 +2%"],
		"desc": "仓库可存放宠物相关道具。"
	},
	"Slot5": {
		"name": "地图残页",
		"kind": "探索道具",
		"rarity": "普通",
		"power": "堆叠 5",
		"base": "效果：探索 +1",
		"affixes": ["区域：彩虹草原"],
		"desc": "地图类道具后续可接地图页进度。"
	},
	"Slot6": {
		"name": "洗练石",
		"kind": "材料",
		"rarity": "稀有",
		"power": "堆叠 6",
		"base": "用途：刷新词条",
		"affixes": ["适用：普通装备", "消耗：1 / 次"],
		"desc": "用于装备洗练页，属于高频材料。"
	},
}


func _ready() -> void:
	_setup_blank_close_zones()
	_setup_item_slots()
	_setup_filter_tabs()
	sort_button.pressed.connect(_on_sort_pressed)
	tip_action_button.pressed.connect(_on_tip_action_pressed)
	item_tooltip.visible = false
	equipped_tooltip.visible = false


func _setup_blank_close_zones() -> void:
	for path in [".", "Card", "Header"]:
		var zone := get_node_or_null(path) as Control
		if zone == null:
			continue
		zone.mouse_filter = Control.MOUSE_FILTER_STOP
		zone.gui_input.connect(_on_blank_gui_input)
	for path in ["Card/Hint", "Card/Capacity"]:
		var label := get_node_or_null(path) as Control
		if label != null:
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _setup_item_slots() -> void:
	for slot_name in _slot_items.keys():
		var slot := get_node_or_null("Card/WarehouseScroll/Grid/" + slot_name) as Control
		if slot == null:
			continue
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		_remember_slot_style(slot)
		slot.mouse_entered.connect(func() -> void: _on_slot_mouse_entered(slot))
		slot.mouse_exited.connect(func() -> void: _hide_item_tip(slot))
		slot.gui_input.connect(func(event: InputEvent) -> void: _on_slot_gui_input(event, slot))
		_set_children_ignore_mouse(slot)


func _setup_filter_tabs() -> void:
	filter_all.pressed.connect(func() -> void: _set_warehouse_filter("all"))
	filter_equip.pressed.connect(func() -> void: _set_warehouse_filter("equip"))
	filter_consumable.pressed.connect(func() -> void: _set_warehouse_filter("consumable"))
	filter_other.pressed.connect(func() -> void: _set_warehouse_filter("other"))
	_set_warehouse_filter("all")


func _set_warehouse_filter(filter_name: String) -> void:
	_warehouse_filter = filter_name
	_close_item_tip()
	for child in $Card/WarehouseScroll/Grid.get_children():
		if child is Control:
			var slot := child as Control
			var item: Dictionary = _slot_items.get(slot.name, {})
			slot.visible = item.is_empty() or _item_matches_filter(item, filter_name)
	_update_filter_buttons()


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
		"all": filter_all,
		"equip": filter_equip,
		"consumable": filter_consumable,
		"other": filter_other,
	}
	for key in buttons.keys():
		var button: Button = buttons[key]
		button.disabled = key == _warehouse_filter


func _on_sort_pressed() -> void:
	_close_item_tip()
	hint_label.text = "已按类型整理"


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
	_on_blank_gui_input(event)


func _on_blank_gui_input(event: InputEvent) -> void:
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
	_fill_item_tip(item)
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


func _fill_item_tip(item: Dictionary) -> void:
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
	_fill_equip_action(item)


func _fill_equip_action(item: Dictionary) -> void:
	var kind := str(item.get("kind", ""))
	var is_equipment := EQUIPMENT_KINDS.has(kind)
	tip_compare.visible = false
	equipped_tooltip.visible = false
	_show_equipped_compare = false
	tip_action_button.visible = true
	if not is_equipment:
		tip_action_button.text = "查看"
		tip_action_button.disabled = true
		return
	tip_action_button.disabled = false
	tip_action_button.text = "装备"
	var equipped_item: Dictionary = _equipped_items.get(kind, {})
	if equipped_item.is_empty():
		tip_compare.visible = true
		tip_compare.text = "已装备：无"
	else:
		_fill_equipped_tip(equipped_item, kind)
		_show_equipped_compare = true


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


func _fill_equipped_tip(item: Dictionary, kind: String) -> void:
	equipped_name.text = str(item.get("name", "未知装备"))
	equipped_kind.text = kind
	equipped_power.text = str(item.get("power", ""))
	equipped_base.text = str(item.get("base", ""))
	equipped_affix.text = "当前身上装备"


func _on_tip_action_pressed() -> void:
	if _current_item.is_empty():
		return
	var kind := str(_current_item.get("kind", ""))
	if not EQUIPMENT_KINDS.has(kind):
		return
	tip_compare.visible = true
	tip_compare.text = "装备入口已就绪\n下一步接入从仓库取出并替换已装备"


func _position_item_tips(slot: Control) -> void:
	var slot_rect := slot.get_global_rect()
	var viewport_size := get_viewport_rect().size
	var panel_rect := get_global_rect()
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
