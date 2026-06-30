extends Control

@onready var status_label: Label = $Card/PetScroll/PetList/Status
@onready var affinity_label: Label = $Card/PetScroll/PetList/Footer
@onready var affinity_bar: ProgressBar = $Card/PetScroll/PetList/AffinityBar
@onready var feed_button: Button = $Card/PetScroll/PetList/ActionRow/FeedButton
@onready var deploy_button: Button = $Card/PetScroll/PetList/ActionRow/DeployButton

var _affinity := 35
var _deployed := true


func _ready() -> void:
	feed_button.pressed.connect(_on_feed_pressed)
	deploy_button.pressed.connect(_on_deploy_pressed)
	_refresh()


func _on_feed_pressed() -> void:
	_affinity = mini(100, _affinity + 10)
	status_label.text = "已喂养：亲密度提升"
	_refresh()


func _on_deploy_pressed() -> void:
	_deployed = true
	status_label.text = "当前出战"
	_refresh()


func _refresh() -> void:
	affinity_bar.value = _affinity
	affinity_label.text = "亲密度 " + str(_affinity) + " / 100"
	deploy_button.text = "已出战" if _deployed else "出战"
	deploy_button.disabled = _deployed
