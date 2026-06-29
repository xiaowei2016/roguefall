extends Control

@onready var power_label: Label = $HeroCard/PowerPanel/PowerLabel
@onready var atk_label: Label = $HeroCard/StatList/AtkLabel
@onready var def_label: Label = $HeroCard/StatList/DefLabel
@onready var hp_label: Label = $HeroCard/StatList/HpLabel
@onready var level_label: Label = $HeroCard/LevelLabel


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
