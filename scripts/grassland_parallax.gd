extends Control
## 彩虹草原分层视差背景 — 7层无缝循环
##
## 世界宽度 3600px，可视窗口 BattleStageClip 裁切 720×180。
## 每层 2 份 TextureRect 横向平铺，通过 stage_scroll_x 驱动不同速率实现视差。

const WORLD_WIDTH := 3600.0
const IMG_NATIVE_W := 5120.0
const IMG_NATIVE_H := 1600.0
const DISPLAY_HEIGHT := 180.0
const DISPLAY_SCALE := DISPLAY_HEIGHT / IMG_NATIVE_H      # 0.1125
const DISPLAY_TEX_W := IMG_NATIVE_W * DISPLAY_SCALE       # 576.0

# [texture_path, scroll_ratio]
const LAYERS := [
	["res://assets/grassland/ChatGPT Image 2026年6月26日 16_13_41 (1).png", 0.15],  # Far 天空渐变
	["res://assets/grassland/ChatGPT Image 2026年6月26日 16_13_42 (2).png", 0.25],  # Far 云朵彩虹
	["res://assets/grassland/ChatGPT Image 2026年6月26日 16_13_43 (3).png", 0.45],  # Mid 远山绿地
	["res://assets/grassland/ChatGPT Image 2026年6月26日 16_13_43 (4).png", 0.55],  # Mid 房屋村庄
	["res://assets/grassland/ChatGPT Image 2026年6月26日 16_13_43 (5).png", 0.85],  # Near 大树岩石
	["res://assets/grassland/ChatGPT Image 2026年6月26日 16_13_43 (6).png", 1.0],   # Ground 草地花边
	["res://assets/grassland/ChatGPT Image 2026年6月26日 16_13_44 (7).png", 1.0],   # Ground 横截面地层
]

var _layer_data: Array = []  # [{ratio, rects}]


static func _load_texture(path: String) -> ImageTexture:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null:
		push_error("[GrasslandParallax] Failed to load image: %s" % path)
		return null
	return ImageTexture.create_from_image(img)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(WORLD_WIDTH, DISPLAY_HEIGHT)

	for layer in LAYERS:
		var path: String = layer[0]
		var ratio: float = layer[1]

		var tex := _load_texture(path)
		if tex == null:
			continue

		var rects: Array[TextureRect] = []
		# 2 份平铺实现无缝循环（2 × 576 = 1152 > 720 viewport）
		for i in range(2):
			var tr := TextureRect.new()
			tr.texture = tex
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			tr.size = Vector2(DISPLAY_TEX_W, DISPLAY_HEIGHT)
			tr.position.x = i * DISPLAY_TEX_W
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(tr)
			rects.append(tr)

		_layer_data.append({"ratio": ratio, "rects": rects})


func update_scroll(stage_scroll_x: float) -> void:
	for layer in _layer_data:
		var ratio: float = layer["ratio"]
		var rects: Array = layer["rects"]
		# 各层以不同比例滚动 → 视差
		var raw_offset := stage_scroll_x * ratio
		var scroll_offset := fmod(raw_offset, DISPLAY_TEX_W)
		if scroll_offset < 0.0:
			scroll_offset += DISPLAY_TEX_W
		for i in range(rects.size()):
			rects[i].position.x = i * DISPLAY_TEX_W - scroll_offset