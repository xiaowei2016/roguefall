# ============================================================
# input_region_manager.gd - 鼠标穿透区域管理器
# ============================================================
# 功能：收集真实交互区 rect，诊断打印，管理鼠标穿透区域。
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


# --------------------------------------------------
# apply_single_battle_widget_passthrough()
# --------------------------------------------------
# 单矩形穿透探针：仅将 BattleWidget 区域设为鼠标接收区，
# 其余窗口区域穿透到底层桌面。
# API 语义：DisplayServer.window_set_mouse_passthrough(polygon)
#   传入 polygon 为"接受鼠标事件"区域，polygon 外穿透。
func apply_single_battle_widget_passthrough() -> void:
	var bw = get_node_or_null("../BattleWidget") as Control
	if not bw:
		push_error("IRM PASSTHROUGH: BattleWidget not found")
		return

	var global_rect: Rect2 = bw.get_global_rect()
	print("IRM PASSTHROUGH: BattleWidget global_rect = pos(%d,%d) size(%d,%d)" % [
		int(global_rect.position.x), int(global_rect.position.y),
		int(global_rect.size.x), int(global_rect.size.y)
	])

	# 将 Rect2 转为 4 顶点 polygon（左上 → 右上 → 右下 → 左下）
	var poly := PackedVector2Array()
	poly.append(Vector2(global_rect.position.x, global_rect.position.y))
	poly.append(Vector2(global_rect.position.x + global_rect.size.x, global_rect.position.y))
	poly.append(Vector2(global_rect.position.x + global_rect.size.x, global_rect.position.y + global_rect.size.y))
	poly.append(Vector2(global_rect.position.x, global_rect.position.y + global_rect.size.y))

	print("IRM PASSTHROUGH: polygon = %s" % poly)
	DisplayServer.window_set_mouse_passthrough(poly)
	print("IRM PASSTHROUGH: applied to window 0")


# --------------------------------------------------
# apply_center_battle_passthrough()
# --------------------------------------------------
# 双矩形穿透探针：CenterDockHost + BattleWidget 连续区域为鼠标接收区，
# 其余窗口区域穿透到底层桌面。
# polygon 连续矩形：(360,0)→(1080,0)→(1080,720)→(360,720)
func apply_center_battle_passthrough() -> void:
	var poly := PackedVector2Array()
	poly.append(Vector2(360, 0))
	poly.append(Vector2(1080, 0))
	poly.append(Vector2(1080, 720))
	poly.append(Vector2(360, 720))

	print("IRM CENTER-BATTLE: polygon = %s" % poly)
	DisplayServer.window_set_mouse_passthrough(poly)
	print("IRM CENTER-BATTLE: applied to window 0")


# --------------------------------------------------
# apply_current_visible_passthrough()
# --------------------------------------------------
# 动态穿透探针：基于节点当前 get_global_rect() 生成 polygon，
# 不写死硬编码坐标。拖动 BattleWidget 后 polygon 自动跟随。
#   BATTLE_ONLY:       仅 BattleWidget
#   CENTER_BATTLE:     Center + Battle 连续矩形
#   LEFT_CENTER_BATTLE:  Left+Center+Battle T形
#   CENTER_RIGHT_BATTLE: Center+Right+Battle T形
#   FULL_T:             全三栏+Battle T形
func apply_current_visible_passthrough() -> void:
	var left = get_node_or_null("../DockLayer/LeftDockHost") as Control
	var center = get_node_or_null("../DockLayer/CenterDockHost") as Control
	var right = get_node_or_null("../DockLayer/RightDockHost") as Control
	var battle = get_node_or_null("../BattleWidget") as Control

	var lv: bool = left != null and left.visible
	var cv: bool = center != null and center.visible
	var rv: bool = right != null and right.visible

	# 实际全局矩形
	var top_rect := Rect2()
	if lv: top_rect = top_rect.merge(left.get_global_rect())
	if cv: top_rect = top_rect.merge(center.get_global_rect())
	if rv: top_rect = top_rect.merge(right.get_global_rect())

	var battle_rect := Rect2()
	if battle:
		battle_rect = battle.get_global_rect()

	var poly := PackedVector2Array()
	var mode_name := "BATTLE_ONLY"

	var any_top: bool = lv or cv or rv
	var has_side: bool = lv or rv  # at least one side dock visible (T-shape needs stem extension)

	if any_top and battle_rect.has_area() and has_side:
		# T形：top bar + battle stem
		var tlx := top_rect.position.x
		var tly := top_rect.position.y
		var trx := top_rect.end.x
		var try_ := top_rect.end.y
		var blx := battle_rect.position.x
		var bly := battle_rect.position.y
		var brx := battle_rect.end.x
		var bry := battle_rect.end.y

		poly.append(Vector2(tlx, tly))
		poly.append(Vector2(trx, tly))

		if brx < trx:
			# stem indented from right → step in before descending
			poly.append(Vector2(trx, try_))
			poly.append(Vector2(brx, try_))
		poly.append(Vector2(brx, bry))
		poly.append(Vector2(blx, bry))

		if blx > tlx:
			# stem indented from left → step in before ascending
			poly.append(Vector2(blx, try_))
			poly.append(Vector2(tlx, try_))

		if lv and cv and rv:
			mode_name = "FULL_T"
		elif lv:
			mode_name = "LEFT_CENTER_BATTLE"
		else:
			mode_name = "CENTER_RIGHT_BATTLE"

	elif cv and battle_rect.has_area():
		# CENTER_BATTLE: Center 已通过布局跟随 Battle，两矩形相邻取最小连续矩形
		var center_rect := center.get_global_rect()
		var ur := center_rect.merge(battle_rect)
		poly.append(ur.position)
		poly.append(Vector2(ur.end.x, ur.position.y))
		poly.append(ur.end)
		poly.append(Vector2(ur.position.x, ur.end.y))
		mode_name = "CENTER_BATTLE"
		print("IRM PASSTHROUGH: battle_rect=(%.0f,%.0f,%.0f,%.0f) center_rect=(%.0f,%.0f,%.0f,%.0f)" % [
			battle_rect.position.x, battle_rect.position.y,
			battle_rect.size.x, battle_rect.size.y,
			center_rect.position.x, center_rect.position.y,
			center_rect.size.x, center_rect.size.y,
		])
		print("IRM PASSTHROUGH: center=%s" % (
			"above" if center_rect.position.y < battle_rect.position.y else "below"
		))

	elif battle_rect.has_area():
		# BATTLE_ONLY
		poly.append(battle_rect.position)
		poly.append(Vector2(battle_rect.end.x, battle_rect.position.y))
		poly.append(battle_rect.end)
		poly.append(Vector2(battle_rect.position.x, battle_rect.end.y))
		mode_name = "BATTLE_ONLY"

	else:
		mode_name = "EMPTY"

	print("IRM PASSTHROUGH: mode=%s polygon=%s" % [mode_name, poly])
	DisplayServer.window_set_mouse_passthrough(poly)
	print("IRM PASSTHROUGH: applied to window 0")
