extends Control

@onready var progress_label: Label = $Card/Progress
@onready var reward_button: Button = $Card/RewardButton


func _ready() -> void:
	reward_button.pressed.connect(_on_reward_pressed)


func _on_reward_pressed() -> void:
	progress_label.text = "收集进度 12%  奖励已领取"
	reward_button.text = "已领取"
	reward_button.disabled = true
