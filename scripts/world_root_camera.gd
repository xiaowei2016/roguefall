extends Node2D
## WorldRoot — minimal Camera2D follow for 3600-wide grassland stage.
## 挂载节点：WorldRoot (GrasslandStage2D)
## 【触发时机】每帧 _process

func _process(_delta: float) -> void:
	var player := $ActorLayer/PlayerActor
	if player:
		$StageCamera2D.position.x = player.global_position.x
