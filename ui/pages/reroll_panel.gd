extends Control

const PREVIEW_AFFIXES := ["攻击 +6", "暴击 +2%", "经验 +3%", "生命 +42", "防御 +5", "幸运 +2"]

@onready var preview_label: Label = $Card/Preview
@onready var action_button: Button = $Card/ActionButton
@onready var attr_list: VBoxContainer = $Card/AttrScroll/AttrList


func _ready() -> void:
	action_button.pressed.connect(_on_action_pressed)


func _on_action_pressed() -> void:
	var locked_count := 0
	for index in attr_list.get_child_count():
		var row := attr_list.get_child(index)
		var lock_box := row.get_node_or_null("Lock") as CheckBox
		var label := row.get_node_or_null("Label") as Label
		if lock_box != null and lock_box.button_pressed:
			locked_count += 1
		elif label != null and index < PREVIEW_AFFIXES.size():
			label.text = PREVIEW_AFFIXES[index]
	preview_label.text = "已预览：保留 " + str(locked_count) + " 条锁定词条"
	action_button.text = "再次洗练"
