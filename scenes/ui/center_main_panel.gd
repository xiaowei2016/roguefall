extends Control

@onready var bag_grid: GridContainer = $bag_area/bag_grid
@onready var attr_vbox: VBoxContainer = $attr_area/attr_vbox

const BAG_SLOT = preload("res://scenes/ui/bag_slot.tscn")
const BAG_COLS: int = 6
const BAG_ROWS: int = 5
const TOTAL_SLOTS: int = BAG_COLS * BAG_ROWS

const ATTR_NAMES := {
	"attr_row_attack": "攻击",
	"attr_row_defense": "防御",
	"attr_row_health": "生命",
}

func _ready() -> void:
	_generate_bag_slots()
	_setup_attr_labels()

func _generate_bag_slots() -> void:
	for i in range(TOTAL_SLOTS):
		var slot := BAG_SLOT.instantiate()
		slot.name = "BagSlot_" + str(i)
		bag_grid.add_child(slot)

func _setup_attr_labels() -> void:
	for node_name: String in ATTR_NAMES:
		var row := attr_vbox.get_node(node_name)
		if row:
			row.get_node("attr_name").text = ATTR_NAMES[node_name]
