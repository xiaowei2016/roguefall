extends Node2D
## DummyEnemy — visual node hierarchy.
## FootMarker marks foot origin (0,0).
## VisualRoot holds placeholder Sprite2D.
## Runtime alignment to BattleBaseline via exported NodePath.

@export var battle_baseline_path: NodePath

var _baseline: Node2D = null


func _ready() -> void:
	if battle_baseline_path:
		_baseline = get_node(battle_baseline_path)


func _physics_process(_delta: float) -> void:
	if _baseline:
		position.y = _baseline.position.y
