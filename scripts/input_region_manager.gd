# ============================================================
# input_region_manager.gd - 鼠标穿透区域收集器（诊断版）
# ============================================================
# 功能：收集真实交互区 rect，诊断打印，不调用 DisplayServer 穿透 API。
# 所属场景：res://scenes/main.tscn → InputRegionManager 节点
# 对应文档：docs/ai_project_knowledge/03_冒险者挂机_UI架构与Dock面板决策_V2.md
# ============================================================
extends Control


# --------------------------------------------------
# 收集规则
# --------------------------------------------------
# ✅ 只收集：visible=true 且 mouse_filter != IGNORE 的节点
# ❌ 显式排除全屏结构层：
#     MainRoot / WindowShell / TransparentCanvas / WindowDragLayer
#     / InputRegionManager（自身）/ DockLayer / BootLabel
# --------------------------------------------------
func collect_interactive_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []

	# 真实交互区节点列表（仅这四个）
	var interactive_paths := [
		"../DockLayer/LeftDockHost",
		"../DockLayer/CenterDockHost",
		"../DockLayer/RightDockHost",
		"../BattleWidget",
	]

	for path in interactive_paths:
		var node = get_node_or_null(path) as Control
		if not node:
			print("IRM WARN: node not found at %s" % path)
			continue
		if not node.visible:
			print("IRM SKIP %s: not visible" % node.name)
			continue
		if node.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			print("IRM SKIP %s: mouse_filter=IGNORE" % node.name)
			continue

		var r = node.get_global_rect()
		rects.append(r)

	return rects


# --------------------------------------------------
# collect_and_print() - 诊断入口
# --------------------------------------------------
# 收集并打印交互区 rect。由 main.gd _ready() 显式调用。
func collect_and_print() -> void:
	print("--- InputRegionManager rect collection ---")
	var rects = collect_interactive_rects()
	print("IRM collected %d interactive rect(s):" % rects.size())
	for i in rects.size():
		var r = rects[i]
		var area = r.size.x * r.size.y
		print("  [%d] pos=(%.0f,%.0f) size=(%.0f,%.0f) area=%.0f" % [
			i, r.position.x, r.position.y, r.size.x, r.size.y, area
		])

	# 安全检查：是否存在全屏误收
	for i in rects.size():
		var r = rects[i]
		if r.size.x >= 1440 and r.size.y >= 720:
			push_error("IRM FATAL: rect[%d] is fullscreen (%.0f×%.0f)! Should be excluded." % [
				i, r.size.x, r.size.y
			])
		if r.size.x <= 1 or r.size.y <= 1:
			push_warning("IRM WARN: rect[%d] is degenerate (%.0f×%.0f)." % [
				i, r.size.x, r.size.y
			])

	if rects.size() == 0:
		push_warning("IRM WARN: zero interactive rects collected.")
	print("--- InputRegionManager done ---")
