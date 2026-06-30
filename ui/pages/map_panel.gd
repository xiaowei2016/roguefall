extends Control

@onready var route_title: Label = $Card/MapScroll/MapContent/RouteTitle
@onready var footer_label: Label = $Card/MapScroll/MapContent/Footer
@onready var enter_button: Button = $Card/EnterButton


func _ready() -> void:
	enter_button.pressed.connect(_on_enter_pressed)


func _on_enter_pressed() -> void:
	route_title.text = "当前区域：彩虹草原"
	footer_label.text = "已进入：草原巡逻"
	enter_button.text = "巡逻中"
	enter_button.disabled = true
