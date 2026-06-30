extends Control

@export_group("World")
@export var view_width := 720.0
@export var world_width := 3600.0
@export var segment_width := 720.0
@export var segment_count := 5
@export var ground_y := 140.0
@export var camera_lead := 280.0

@export_group("Auto Battle")
@export var player_speed := 95.0
@export var attack_range := 42.0
@export var attack_interval := 0.55
@export var walk_bob_height := 2.0

@onready var world_root: Control = $Frame/world_root
@onready var segment_template: Control = $Frame/world_root/segment_0_preview
@onready var player_anchor: Control = $Frame/world_root/actor_layer/player_anchor
@onready var enemy_anchor: Control = $Frame/world_root/actor_layer/enemy_anchor
@onready var player_visual: Control = $Frame/world_root/actor_layer/player_anchor/PlayerVisual
@onready var enemy_visual: Control = $Frame/world_root/actor_layer/enemy_anchor/EnemyVisual
@onready var status_label: Label = $Frame/StatusBadge/StatusLabel

var player_x := 180.0
var enemy_x := 520.0
var direction := 1.0
var enemy_hp := 3
var attack_timer := 0.0
var step_time := 0.0
var hit_flash := 0.0
var active_world_width := 3600.0


func _ready() -> void:
	active_world_width = segment_width * max(1, segment_count)
	world_width = active_world_width
	world_root.size.x = active_world_width
	_build_loop_segments()
	_spawn_enemy(520.0)
	_apply_actor_positions()


func _build_loop_segments() -> void:
	segment_template.position.x = 0.0
	for index in range(1, segment_count):
		var existing := world_root.get_node_or_null("segment_%d_runtime" % index)
		if existing != null:
			existing.queue_free()
		var segment := segment_template.duplicate()
		segment.name = "segment_%d_runtime" % index
		segment.position.x = segment_width * index
		world_root.add_child(segment)
		world_root.move_child(segment, segment_template.get_index() + index)


func _process(delta: float) -> void:
	step_time += delta
	attack_timer = maxf(0.0, attack_timer - delta)
	hit_flash = maxf(0.0, hit_flash - delta)

	var distance := enemy_x - player_x
	if absf(distance) > attack_range:
		direction = signf(distance) if distance != 0.0 else direction
		player_x += direction * player_speed * delta
		if player_x <= _world_min_x():
			player_x = _world_min_x()
			direction = 1.0
			_spawn_enemy(_next_enemy_x())
		elif player_x >= _world_max_x():
			player_x = _world_max_x()
			direction = -1.0
			_spawn_enemy(_next_enemy_x())
		status_label.text = "巡逻找怪中"
	else:
		status_label.text = "自动战斗中"
		if attack_timer <= 0.0:
			attack_timer = attack_interval
			enemy_hp -= 1
			hit_flash = 0.14
			if enemy_hp <= 0:
				_gain_reward()
				_spawn_enemy(_next_enemy_x())

	_apply_actor_positions()


func _apply_actor_positions() -> void:
	var bob := sin(step_time * 9.0) * walk_bob_height
	player_anchor.position = Vector2(player_x, ground_y + bob)
	enemy_anchor.position = Vector2(enemy_x, ground_y)

	var camera_x := clampf(player_x - camera_lead, 0.0, active_world_width - view_width)
	world_root.position.x = -camera_x

	player_visual.scale.x = direction
	enemy_visual.scale = Vector2.ONE * (1.18 if hit_flash > 0.0 else 1.0)
	enemy_visual.modulate = Color(1, 0.9, 0.9, 1) if hit_flash > 0.0 else Color.WHITE


func _next_enemy_x() -> float:
	var forward := player_x + direction * randf_range(260.0, 560.0)
	if forward < _world_min_x() or forward > _world_max_x():
		direction *= -1.0
		forward = player_x + direction * randf_range(260.0, 560.0)
	return clampf(forward, _world_min_x(), _world_max_x())


func _spawn_enemy(x: float) -> void:
	enemy_x = clampf(x, _world_min_x(), _world_max_x())
	enemy_hp = 3


func _gain_reward() -> void:
	if has_node("/root/GameData"):
		GameData.gold += 1
		GameData.exp = mini(GameData.next_exp, GameData.exp + 5)


func _world_min_x() -> float:
	return 90.0


func _world_max_x() -> float:
	return maxf(_world_min_x(), active_world_width - 90.0)
