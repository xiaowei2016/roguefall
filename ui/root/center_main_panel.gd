extends Control

const BAG_EQUIP_PANEL := preload("res://ui/panels/bag_equip_panel.tscn")
const PLAYER_ATTR_PANEL := preload("res://ui/panels/player_attr_panel.tscn")

@onready var popup_parent: Control = $popup_parent

var _current_popup: Control = null


func _ready() -> void:
	pass


func show_bag_equip_panel() -> void:
	_clear_popup()
	_current_popup = BAG_EQUIP_PANEL.instantiate()
	_current_popup.layout_mode = 1
	_current_popup.anchors_preset = Control.PRESET_FULL_RECT
	popup_parent.add_child(_current_popup)
	popup_parent.visible = true


func show_player_attr_panel() -> void:
	_clear_popup()
	_current_popup = PLAYER_ATTR_PANEL.instantiate()
	_current_popup.layout_mode = 1
	_current_popup.anchors_preset = Control.PRESET_FULL_RECT
	popup_parent.add_child(_current_popup)
	popup_parent.visible = true


func hide_popup() -> void:
	_clear_popup()
	popup_parent.visible = false


func _clear_popup() -> void:
	if _current_popup:
		_current_popup.queue_free()
		_current_popup = null
	for child in popup_parent.get_children():
		child.queue_free()
