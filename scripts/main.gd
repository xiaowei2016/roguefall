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
	# 输入区域收集诊断（委托给 InputRegionManager 节点）
	$InputRegionManager.collect_and_print()
	# 动态穿透探针：根据 CenterDockHost.visible 自适应
	$InputRegionManager.apply_current_visible_passthrough()
	# 背包按钮：点击切换 CenterDockHost 可见性
	$BattleWidget/BagButton.pressed.connect(_on_bag_button_pressed)
	# 左栏/右栏按钮（在 CenterDebugPanel 内）
	$DockLayer/CenterDockHost/CenterDebugPanel/LeftButton.pressed.connect(_on_left_button_pressed)
	$DockLayer/CenterDockHost/CenterDebugPanel/RightButton.pressed.connect(_on_right_button_pressed)

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
# --------------------------------------------------
# _on_bag_button_pressed() - 背包按钮点击回调
# --------------------------------------------------
# 切换 CenterDockHost 可见性，用于后续验证三栏打开与多区域穿透。
func _on_bag_button_pressed() -> void:
	var center = $DockLayer/CenterDockHost
	center.visible = not center.visible
	print("BagButton pressed, CenterDockHost visible = %s" % center.visible)
	# 刷新 passthrough 区域
	$InputRegionManager.apply_current_visible_passthrough()


# --------------------------------------------------
# _on_left_button_pressed() - 左栏按钮点击回调
# --------------------------------------------------
func _on_left_button_pressed() -> void:
	var left = $DockLayer/LeftDockHost
	left.visible = not left.visible
	print("LeftButton pressed, LeftDockHost visible = %s" % left.visible)
	$InputRegionManager.apply_current_visible_passthrough()


# --------------------------------------------------
# _on_right_button_pressed() - 右栏按钮点击回调
# --------------------------------------------------
func _on_right_button_pressed() -> void:
	var right = $DockLayer/RightDockHost
	right.visible = not right.visible
	print("RightButton pressed, RightDockHost visible = %s" % right.visible)
	$InputRegionManager.apply_current_visible_passthrough()


# --------------------------------------------------
# _process(delta) - 每帧主循环
# --------------------------------------------------
func _process(_delta: float) -> void:
	pass
