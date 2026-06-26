extends Node2D
## Minimal DummyEnemy for testing patrol-seek-attack.
## Renders a 50x80 red rectangle anchored at foot.

func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-25, -80, 50, 80), Color.RED)
