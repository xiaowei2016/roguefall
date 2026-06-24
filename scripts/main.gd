# ============================================================
# main.gd - 冒险者挂机 主入口脚本
# ============================================================
# 功能：应用启动入口，挂载到场景根节点 MainRoot
# 所属场景：res://scenes/main.tscn
# 节点树：MainRoot(Control) → WindowShell / DockLayer / BattleWidget ...
# 对应文档：docs/ai_project_knowledge/03_冒险者挂机_UI架构与Dock面板决策_V2.md
# ============================================================

## 继承 Control：作为整个 UI 树的根容器。
## MainRoot 已在 main.tscn 中设为全屏锚点（anchor 0,0 → 1,1），
## 尺寸由 project.godot 中 1440×720 决定，子节点用锚点比例自适应。
extends Control


# --------------------------------------------------
# _ready() - 场景就绪回调
# --------------------------------------------------
# 【触发时机】场景树构建完毕、所有子节点 _ready 全部执行完成后调用。
# 【当前功能】打印启动确认信息，验证项目骨架可正常运行。
# 【后续扩展】在此初始化核心子系统：
#   - WindowShell：透明窗口属性
#   - InputRegionManager：鼠标穿透区域计算
#   - DockLayoutController：面板打开/关闭/位置计算
#   - BattleWidget：常驻挂机条可见
func _ready() -> void:
	print("冒险者挂机 Boot OK")
	# rect 诊断：打印四个关键节点矩形
	_print_dock_rects()
	# 输入区域收集诊断
	_print_input_region_collection()

func _print_dock_rects() -> void:
	var nodes = {
		"MainRoot": self,
		"WindowShell": $WindowShell,
		"TransparentCanvas": $TransparentCanvas,
		"WindowDragLayer": $WindowDragLayer,
		"InputRegionManager": $InputRegionManager,
		"DockLayer": $DockLayer,
		"LeftDockHost": $DockLayer/LeftDockHost,
		"CenterDockHost": $DockLayer/CenterDockHost,
		"RightDockHost": $DockLayer/RightDockHost,
		"BattleWidget": $BattleWidget,
		"BootLabel": $BattleWidget/BootLabel,
	}
	for name in nodes:
		var node = nodes[name]
		var r = node.get_rect()
		var mf = node.mouse_filter
		var mf_str = "STOP" if mf == 0 else ("PASS" if mf == 1 else "IGNORE")
		print("FILTER %s: mf=%d(%s) rect=(%.0f,%.0f,%.0f,%.0f)" % [
			name, mf, mf_str, r.position.x, r.position.y, r.size.x, r.size.y
		])


# --------------------------------------------------
# _print_input_region_collection() - IRM 诊断
# --------------------------------------------------
# 收集真实交互区 rect 并打印，验证全屏容器未被误收。
# 收集规则：
#   ✅ 只收集 visible=true 且 mouse_filter != IGNORE 的节点
#   ❌ 显式排除全屏结构层：MainRoot / WindowShell / TransparentCanvas
#      / WindowDragLayer / InputRegionManager / DockLayer / BootLabel
func _print_input_region_collection() -> void:
	print("--- InputRegionManager rect collection ---")

	var candidate_paths := [
		"DockLayer/LeftDockHost",
		"DockLayer/CenterDockHost",
		"DockLayer/RightDockHost",
		"BattleWidget",
	]

	var rects: Array[Rect2] = []

	for path in candidate_paths:
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


# --------------------------------------------------
# _process(delta) - 每帧主循环
# --------------------------------------------------
# 【参数】_delta：距上一帧的间隔时间（秒），用于帧率无关的平滑计算。
# 【当前】空占位，不做任何操作（Godot 要求 _process 不存在的节点
#   默认不会进入 process 队列；显式写出 allow_empty 便于后续扩展）。
# 【后续扩展】挂机主循环逻辑：
#   - 自动战斗计时
#   - 定时掉落判定
#   - 经验/金币自动增长
#   - UI 实时刷新（血条/经验条/金币显示）
func _process(_delta: float) -> void:
	pass
