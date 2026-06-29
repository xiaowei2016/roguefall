extends Control

@onready var attr_vbox: VBoxContainer = $attr_area/attr_vbox

const ATTR_NAMES := {
	"attr_row_attack": "攻击",
	"attr_row_defense": "防御",
	"attr_row_health": "生命",
}

func _ready() -> void:
	_setup_attr_labels()

func _setup_attr_labels() -> void:
	for node_name: String in ATTR_NAMES:
		var row := attr_vbox.get_node(node_name)
		if row:
			row.get_node("attr_name").text = ATTR_NAMES[node_name]
