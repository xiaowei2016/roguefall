extends Node2D

## Patrol-Seek-Attack state machine for PlayerActor.
## States: idle / run / attack

@onready var animated_sprite: AnimatedSprite2D = $VisualRoot/AnimatedSprite2D
@onready var battle_baseline: Node2D = $"../BattleBaseline"

const MOVE_SPEED: float = 80.0
const ATTACK_RANGE: float = 60.0
const PATROL_MIN_X: float = 80.0
const PATROL_MAX_X: float = 640.0

var patrol_direction: int = 1  # 1=right, -1=left
var is_attacking: bool = false


func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if is_attacking:
		return

	var enemies := _get_enemy_nodes()

	if enemies.is_empty():
		_patrol(delta)
	else:
		var nearest := _find_nearest(enemies)
		if nearest:
			_seek(nearest, delta)


func _patrol(delta: float) -> void:
	position.y = battle_baseline.position.y
	position.x += patrol_direction * MOVE_SPEED * delta

	if position.x >= PATROL_MAX_X:
		position.x = PATROL_MAX_X
		patrol_direction = -1
	elif position.x <= PATROL_MIN_X:
		position.x = PATROL_MIN_X
		patrol_direction = 1

	animated_sprite.flip_h = patrol_direction < 0
	_update_animation("run")


func _seek(enemy: Node2D, delta: float) -> void:
	position.y = battle_baseline.position.y

	var dx: float = enemy.global_position.x - global_position.x
	var dist: float = abs(dx)

	if dist <= ATTACK_RANGE:
		_start_attack()
		return

	var direction := sign(dx)
	position.x += direction * MOVE_SPEED * delta

	animated_sprite.flip_h = dx < 0
	_update_animation("run")


func _start_attack() -> void:
	is_attacking = true
	_update_animation("attack")


func _on_animation_finished() -> void:
	if is_attacking and animated_sprite.animation == "attack":
		is_attacking = false


func _get_enemy_nodes() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D:
			result.append(node as Node2D)
	return result


func _find_nearest(enemies: Array[Node2D]) -> Node2D:
	if enemies.is_empty():
		return null
	var nearest: Node2D = enemies[0]
	var min_dist_sq: float = global_position.distance_squared_to(nearest.global_position)
	for i in range(1, enemies.size()):
		var e: Node2D = enemies[i]
		var d_sq: float = global_position.distance_squared_to(e.global_position)
		if d_sq < min_dist_sq:
			min_dist_sq = d_sq
			nearest = e
	return nearest


func _update_animation(anim_name: String) -> void:
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)
