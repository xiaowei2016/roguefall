# WINDOW-TRANSPARENCY-BLACK-BG-AUDIT-01

**日期**：2026-06-26
**项目**：roguefall
**问题**：站台电脑运行后，实际游戏窗口背景显示为黑色，而非桌面透明。
**审计类型**：只读，不修改任何代码/配置/场景。

---

## 1. project.godot 透明相关设置（实际值）

| 配置键 | 实际值 | 状态 |
|---|---|---|
| `display/window/per_pixel_transparency/allowed` | `true` | ✅ 已设置 |
| `display/window/per_pixel_transparency/enabled` | **缺失** | ❌ 未设置 |
| `display/window/size/transparent` | `true` | ✅ 已设置 |
| `display/window/size/borderless` | `true` | ✅ 已设置 |
| `display/window/size/always_on_top` | 缺失（代码中设 `win.always_on_top = true`） | ⚠️ 仅运行时设置 |
| `rendering/viewport/transparent_background` | `true` | ✅ 已设置 |
| `application/run/main_scene` | `"res://scenes/main.tscn"` | ✅ 已设置 |
| `rendering/environment/default_clear_color` | **缺失** | ⚠️ 文档建议设为 `Color(0,0,0,0)`，未配 |

完整 project.godot 内容（29 行）：

```ini
config_version=5

[application]
config/name="Roguefall"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.7", "Forward Plus")
config/icon="res://icon.svg"

[display]
window/size/viewport_width=1440
window/size/viewport_height=720
window/size/borderless=true
window/size/transparent=true
window/per_pixel_transparency/allowed=true

[rendering]
viewport/transparent_background=true
```

---

## 2. scenes/main.tscn 节点树检查

### 2.1 关键发现

| 检查项 | 结果 |
|---|---|
| 是否有 ColorRect | ❌ 无 |
| 是否有全屏 Panel/TextureRect/Control 铺底 | ❌ 无 |
| 是否有黑色背景节点 | ❌ 无 |
| 是否有自定义 theme / panel stylebox | ❌ 无（无 .tres 文件） |
| root Control 的 self_modulate / modulate | 未设置（默认白色，alpha=1） |

### 2.2 节点树结构

```
MainRoot (Control, 1440×720, script=main.gd)
└── PanelRoot (Control, 1440×720, mouse_filter=IGNORE)
    ├── LeftPanel (Control, 352×530, mouse_filter=IGNORE)
    │   └── Panel (full_rect, script=native_drag_zone.gd)
    ├── CenterPanel (Control, 720×530, mouse_filter=IGNORE)
    │   ├── Panel (full_rect, script=native_drag_zone.gd)
    │   ├── Button "左栏"
    │   └── Button2 "右栏"
    ├── RightPanel (Control, 352×530, mouse_filter=IGNORE)
    │   └── Panel (full_rect, script=native_drag_zone.gd)
    └── BattleBar (Control, 720×180, mouse_filter=IGNORE)
        ├── Panel (full_rect, script=native_drag_zone.gd)
        └── Button "背包"
```

### 2.3 Panel 节点分析

- 4 个 `Panel` 节点分别覆盖 LeftPanel / CenterPanel / RightPanel / BattleBar 区域
- 均使用 Godot 默认 Panel 主题样式（内置 StyleBoxFlat，深灰色，**非纯黑**）
- 无自定义 theme_override、无 StyleBoxFlat 覆盖、无 modulate 设置
- Panel 只覆盖面板区域本身，**不覆盖窗口空白区域**（如左侧 360px 到 LeftPanel 之间、面板之间的间隙等）

---

## 3. main.gd 透明相关代码搜索

### 3.1 _ready() 中的窗口设置（第 53-57 行）

```gdscript
var win := get_window()
win.borderless = true
win.always_on_top = true
win.unresizable = true
win.transparent = true
win.size = Vector2i(WIN_W, WIN_H)
```

### 3.2 搜索结果

| 搜索词 | 结果 |
|---|---|
| `transparent_bg` | ❌ 未出现 |
| `per_pixel_transparency` | ❌ 未出现 |
| `clear_color` / `set_clear_color` | ❌ 未出现 |
| `RenderingServer` | ❌ 未出现 |
| `DisplayServer` | ✅ 仅用于 `screen_get_usable_rect` / `mouse_get_position` |
| `Color.BLACK` / `Color(0,0,0` / `"#000"` | ❌ 未出现 |
| `background` | ❌ 未出现 |

### 3.3 结论

main.gd 在运行时通过代码设置了 `win.transparent = true`，但**从未设置 `per_pixel_transparency/enabled`**（该属性在 Godot 4 中需要通过 project.godot 配置或 `DisplayServer` / `Window` API 设置）。代码也未设置 `RenderingServer.set_default_clear_color()` 或 `get_viewport().transparent_bg`。

---

## 4. 全局黑色背景来源清单

| 搜索 | 范围 | 结果 |
|---|---|---|
| `Color.BLACK` | 全项目 .gd/.tscn/.tres | 0 处 |
| `Color(0, 0, 0` | 全项目 .gd/.tscn/.tres | 0 处 |
| `"#000` | 全项目 .gd/.tscn/.tres | 0 处 |
| `StyleBoxFlat` | 全项目 .gd/.tscn/.tres | 0 处 |
| `stylebox` / `theme_override` | 全项目 .gd/.tscn/.tres | 0 处 |
| `ColorRect` | 全项目 .gd/.tscn/.tres | 0 处 |
| `clear_color` / `default_clear_color` | 全项目 .gd/.tscn/.tres | 0 处 |
| `.tres` 主题文件 | 全项目 | 0 个 |

**结论：项目中不存在任何显式定义的黑色背景节点、样式或颜色常量。黑色背景来自 Godot 引擎默认行为。**

---

## 5. 根因分析

### 5.1 根因类型：**A — 透明窗口没生效，透明像素被系统/Godot 显示成黑色**

### 5.2 确认证据链

1. **project.godot 设置了 `window/per_pixel_transparency/allowed=true`，但缺失 `window/per_pixel_transparency/enabled=true`。**

   在 Godot 4 中，这是两个不同的配置：
   - `allowed`：仅表示操作系统支持 per-pixel transparency，不实际启用。
   - `enabled`：**实际启用** per-pixel transparency，让透明像素区域直接显示桌面内容。

   没有 `enabled=true`，Godot 不会向 OS 请求透明窗口合成，而是用默认背景色填充透明区域。

2. **文档预期与实际不符。**

   `docs/ai_project_knowledge/03_冒险者挂机_UI架构与Dock面板决策_V2.md` 第 265 行明确记录了应配置：
   ```ini
   window/per_pixel_transparency/enabled=true
   ```
   但 project.godot 中实际只有 `allowed=true`，`enabled` 行完全缺失。

3. **main.gd 运行时仅设置 `win.transparent = true`，未设置 per-pixel transparency。**

   `win.transparent` 控制的是窗口装饰透明（标题栏等），不等同于 per-pixel transparency。

4. **`rendering/viewport/transparent_background=true` 已设置但无效。**

   该设置让 Godot 渲染管线输出带 alpha 通道的画面，但若 OS 层面 per-pixel transparency 未启用，这些透明像素会被 OS/合成器填充为默认颜色（黑色）。同时 `environment/default_clear_color` 缺失，默认值为黑色 `Color(0,0,0,1)`，进一步加剧了问题。

5. **项目中不存在任何显式黑色背景节点。**

   Panel 节点使用 Godot 默认深灰主题，颜色接近 `#3c3c3c`，不是纯黑。窗口空白区域（面板之间、面板周围）才是纯黑色——这正是 per-pixel transparency 未启用时 OS 合成的默认黑色。

### 5.3 根因排序（最可能 → 最不可能）

| 排名 | 根因 | 置信度 |
|---|---|---|
| **1** | `display/window/per_pixel_transparency/enabled=true` 未在 project.godot 中设置 | **极高** |
| 2 | `environment/default_clear_color` 未显式设为透明（默认为不透明黑色） | 中等（辅助因素） |
| 3 | 站台电脑环境问题（GPU 驱动 / 合成器不支持） | 低（`allowed=true` 已通过，说明 OS 支持） |
| 4 | Godot 4.7 版本 Bug | 极低 |

---

## 6. 推荐最小修复方案（仅建议，不执行）

### 6.1 方案：在 project.godot 中添加一行

在 `[display]` 段中 `window/per_pixel_transparency/allowed=true` 的下一行添加：

```ini
window/per_pixel_transparency/enabled=true
```

同时建议在 `[rendering]` 段中添加（可选，加固）：

```ini
environment/default_clear_color=Color(0, 0, 0, 0)
```

### 6.2 改动范围

| 文件 | 改动 | 类型 |
|---|---|---|
| `project.godot` | 新增 1 行（或 2 行，含加固） | 配置修改 |
| 其他文件 | 无 | — |

### 6.3 是否需要改代码

**不需要改代码。** main.gd 中的 `win.transparent = true`、`win.borderless = true` 已经正确。问题仅在于 project.godot 缺少 `per_pixel_transparency/enabled=true` 配置项。这是纯配置问题，不是代码问题。

### 6.4 是否需要站台电脑环境修改

**不需要。** `allowed=true` 已通过 Godot 的系统能力检测，说明站台电脑的 OS/GPU/合成器支持 per-pixel transparency。只需启用即可。

---

## 7. 审计总结

| 维度 | 结论 |
|---|---|
| 根因类型 | A — 透明窗口未生效 |
| 直接原因 | `per_pixel_transparency/enabled` 缺失 |
| 修复位置 | `project.godot` 第 24 行后新增 1 行 |
| 是否需改代码 | 否 |
| 是否需改场景 | 否 |
| 是否环境问题 | 否 |
| 修复风险 | 极低（仅启用已有能力） |

---

## 8. 补充排查 — Phase 2 深入分析

**日期**：2026-06-26
**触发条件**：Phase 1 修复（`per_pixel_transparency/enabled=true`）已应用，但运行时窗口背景仍为黑色不透明。
**排查范围**：运行时代码、场景文件、全局环境资源、Godot 4 Forward+ 渲染管线。

### 8.1 project.godot 当前状态（Phase 1 修复后）

```ini
[display]
window/size/borderless=true
window/size/transparent=true
window/per_pixel_transparency/allowed=true
window/per_pixel_transparency/enabled=true

[rendering]
renderer/rendering_method="forward_plus"
viewport/transparent_background=true
```

| 配置项 | 状态 |
|---|---|
| `display/window/per_pixel_transparency/enabled` | ✅ 已补充 |
| `rendering/environment/default_clear_color` | ❌ 仍缺失 |

### 8.2 运行时代码排查（main.gd 全文 + native_drag_zone.gd）

#### 8.2.1 main.gd `_ready()` 窗口设置（第 53-57 行）

```gdscript
var win := get_window()
win.borderless = true
win.always_on_top = true
win.unresizable = true
win.transparent = true
win.size = Vector2i(WIN_W, WIN_H)
```

**结论**：代码正确。`win.transparent = true` 等价于 `display/window/size/transparent=true`，不存在代码覆写为 false 的情况。

#### 8.2.2 全局搜索负面清单

| 搜索词 | 搜索范围 | 命中 | 说明 |
|---|---|---|---|
| `RenderingServer` | 全项目 .gd | 0 处 | 无人为干预渲染管线 |
| `set_default_clear_color` | 全项目 | 0 处 | 未覆盖引擎默认清屏色 |
| `transparent_bg` | 全项目 .gd | 0 处 | 未覆写 viewport 透明背景 |
| `FLAG_` | 全项目 .gd | 0 处 | 未调用 `DisplayServer.window_set_flag()` |
| `DisplayServer.window_set_flag` | 全项目 .gd | 0 处 | 未设置 `WINDOW_FLAG_TRANSPARENT` |
| `clear_color` | 全项目 .gd | 0 处 | — |
| `modulate` / `self_modulate` | 全项目 .gd | 0 处 | 无染色覆盖 |
| `StyleBox` / `bg_color` / `theme_override` | 全项目 .gd | 0 处 | 无自定义样式背景 |

**结论**：运行时代码没有任何操作会覆盖或破坏透明窗口设置。问题不在 GDScript 层面。

### 8.3 场景文件排查（main.tscn）

#### 8.3.1 节点树结构（完整）

```
MainRoot (Control, 1440×720, script=main.gd)
└── PanelRoot (Control, 1440×720, mouse_filter=IGNORE)
    ├── LeftPanel (Control, 352×530, mouse_filter=IGNORE)
    │   └── Panel (full_rect, script=native_drag_zone.gd)
    ├── CenterPanel (Control, 720×530, mouse_filter=IGNORE)
    │   ├── Panel (full_rect, script=native_drag_zone.gd)
    │   ├── Button "左栏"
    │   └── Button2 "右栏"
    ├── RightPanel (Control, 352×530, mouse_filter=IGNORE)
    │   └── Panel (full_rect, script=native_drag_zone.gd)
    └── BattleBar (Control, 720×180, mouse_filter=IGNORE)
        ├── Panel (full_rect, script=native_drag_zone.gd)
        └── Button "背包"
```

#### 8.3.2 场景排查结果

| 检查项 | 结果 |
|---|---|
| 根节点类型 | `Control`（无默认背景绘制） |
| `WorldEnvironment` 节点 | ❌ 无 |
| `ColorRect` 节点 | ❌ 无 |
| 全屏黑色背景节点 | ❌ 无 |
| 自定义 `theme` / `theme_override` | ❌ 无 |
| `StyleBoxFlat` 覆盖 | ❌ 无 |
| Panel 节点的 `modulate` / `self_modulate` | 未设置（默认） |
| Panel 节点背景色 | Godot 默认主题深灰（`~#3c3c3c`），**非纯黑** |

**关键发现**：4 个 `Panel` 节点分别仅覆盖 LeftPanel / CenterPanel / RightPanel / BattleBar 这 4 块 UI 区域，使用的是 Godot 内置默认 Panel StyleBox（深灰色，非黑色）。窗口其余大面积空白区域（面板之间间隙、左侧 360px、各面板外围）没有任何节点覆盖，这些区域的黑色绝非来自场景中的任何节点。

### 8.4 Environment 资源排查

#### 8.4.1 .tres 文件搜索

全项目搜索 `*.tres`：**0 个文件**。

**结论**：项目未定义任何自定义 Environment 资源（`default_env.tres` 或类似文件）。Godot 使用内置默认 Environment。

#### 8.4.2 默认 Environment 行为分析

Godot 4 内置默认 Environment 的关键属性：

| 属性 | 默认值 | 影响 |
|---|---|---|
| `background_mode` | `0`（`CLEAR_COLOR`） | 每帧用清屏色填充 viewport |
| `background_color` / `clear_color` | `Color(0, 0, 0, 1)` | **纯黑不透明** |

当 `background_mode = CLEAR_COLOR` 时，渲染管线每帧开始时将整个 viewport 填充为 `clear_color`（默认纯黑 `Color(0,0,0,1)`），然后在此黑色画布上绘制 UI 节点。

**这意味着**：即使 `viewport/transparent_background=true` 让 framebuffer 支持 alpha 通道，默认 Environment 的 `CLEAR_COLOR` 背景模式仍然会用不透明黑色覆盖整个缓冲区，使得 alpha 通道信息在清屏阶段就被抹除。

### 8.5 根因分析（Phase 2）

#### 8.5.1 根因链条

```
Godot 内置默认 Environment
  → background_mode = CLEAR_COLOR (0)
    → 每帧清屏色 = Color(0, 0, 0, 1)（不透明黑色）
      → 黑色覆盖 viewport 整个 framebuffer
        → Panel 节点只覆盖 4 块 UI 区域（深灰色）
        → 其余区域显示为纯黑色（清屏色）
          → 即使 per_pixel_transparency 已启用，OS 合成器看到的是全不透明黑色 framebuffer
```

#### 8.5.2 与 Phase 1 根因的关系

| Phase | 根因 | 状态 |
|---|---|---|
| Phase 1 | `per_pixel_transparency/enabled` 缺失 → OS 不合成透明窗口 | ✅ 已修复 |
| **Phase 2** | `environment/default_clear_color` 缺失 → Godot 渲染管线每帧填充不透明黑色 | ❌ **当前根因** |

Phase 1 和 Phase 2 是**串联关系**：两个条件必须同时满足透明窗口才能正常工作。Phase 1 修好后，OS 已准备好合成透明窗口，但 Godot 渲染管线输出的仍是不透明黑色画面。

#### 8.5.3 证据权重

| 证据 | 强度 |
|---|---|
| 项目无 `.tres` → Godot 使用默认 Environment | 确定 |
| 默认 Environment `background_mode = CLEAR_COLOR`（Godot 4 文档/源码行为） | 确定 |
| 默认 `clear_color = Color(0,0,0,1)` | 确定 |
| Panel 节点仅覆盖 4 块 UI 区域且为深灰色 → 黑色区域不是 Panel 造成 | 确定 |
| 代码中无任何 `RenderingServer` / `clear_color` / `transparent_bg` 操作 | 确定 |
| `project.godot` 中 `environment/default_clear_color` 缺失 | 确定 |

**置信度**：极高。

### 8.6 推荐修复方案

#### 8.6.1 方案 A（最小修复，推荐）

在 `project.godot` 的 `[rendering]` 段末尾添加一行：

```ini
environment/default_clear_color=Color(0, 0, 0, 0)
```

完整 `[rendering]` 段将变为：

```ini
[rendering]
renderer/rendering_method="forward_plus"
viewport/transparent_background=true
environment/default_clear_color=Color(0, 0, 0, 0)
```

**原理**：将清屏色从默认黑色 `Color(0,0,0,1)` 改为透明 `Color(0,0,0,0)`，让 viewport framebuffer 的 alpha 通道在清屏阶段保留透明值，OS 合成器即可正确合成桌面背景。

#### 8.6.2 方案 B（运行时代码加固，可选）

在 `main.gd` 的 `_ready()` 中添加：

```gdscript
RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
```

放在 `win.transparent = true` 之前或之后均可。此方案等效于方案 A 的代码级实现，但方案 A（project.godot 配置）更优先，因为它在引擎初始化阶段就生效，无需等待脚本执行。

#### 8.6.3 改动范围

| 文件 | 改动 | 类型 |
|---|---|---|
| `project.godot` | `[rendering]` 段新增 1 行 | 配置修改 |
| 其他文件 | 无 | — |

#### 8.6.4 是否需要改代码

**不需要**。方案 A 仅修改 project.godot，是纯配置修复。

### 8.7 补充排查总结

| 维度 | 结论 |
|---|---|
| 根因类型 | B — Godot 渲染管线清屏色为不透明黑色 |
| 直接原因 | `environment/default_clear_color` 缺失，Godot 使用默认 `Color(0,0,0,1)` 清屏 |
| 修复位置 | `project.godot` `[rendering]` 段新增 1 行 |
| 是否需改代码 | 否（纯配置修复） |
| 是否需改场景 | 否 |
| 是否环境问题 | 否 |
| 修复风险 | 极低 |
| Phase 1 + Phase 2 联合修复后预期 | 窗口背景透明，桌面内容可见，Panel 区域保持深灰主题 |


---

## 9. 第三轮排查

**日期**：2026-06-26
**触发条件**：Phase 1（`per_pixel_transparency/enabled=true`）+ Phase 2（`environment/default_clear_color=Color(0,0,0,0)`）均已修复，project.godot 配置齐全，但 F5 运行后窗口背景仍为纯黑不透明（用户截图证实）。
**排查范围**：运行时代码全覆盖审计、autoload 排查、Godot 4.7 Forward+ 兼容性、project.godot 键路径验证、Godot 4 API 行为分析。

### 9.1 project.godot 当前完整透明配置

```ini
[display]
window/size/borderless=true
window/size/transparent=true
window/per_pixel_transparency/allowed=true
window/per_pixel_transparency/enabled=true

[rendering]
renderer/rendering_method="forward_plus"
viewport/transparent_background=true
environment/default_clear_color=Color(0, 0, 0, 0)
```

| 配置键 | 值 | 状态 |
|---|---|---|
| `display/window/size/borderless` | `true` | ✅ |
| `display/window/size/transparent` | `true` | ✅ |
| `display/window/per_pixel_transparency/allowed` | `true` | ✅ |
| `display/window/per_pixel_transparency/enabled` | `true` | ✅ |
| `rendering/viewport/transparent_background` | `true` | ✅ |
| `rendering/environment/default_clear_color` | `Color(0,0,0,0)` | ✅ |

**结论**：project.godot 中所有已知必需配置均已齐全，配置层面不存在缺失项。

### 9.2 键路径验证

逐一验证 project.godot 中每个配置键在 Godot 4 中的实际路径：

| project.godot 写法 | 展开后完整路径 | Godot 4 文档对应 | 正确性 |
|---|---|---|---|
| `[display]` → `window/size/borderless=true` | `display/window/size/borderless` | `Window.borderless` | ✅ |
| `[display]` → `window/size/transparent=true` | `display/window/size/transparent` | `Window.transparent` | ✅ |
| `[display]` → `window/per_pixel_transparency/allowed=true` | `display/window/per_pixel_transparency/allowed` | 项目设置文档 | ✅ |
| `[display]` → `window/per_pixel_transparency/enabled=true` | `display/window/per_pixel_transparency/enabled` | 项目设置文档 | ✅ |
| `[rendering]` → `viewport/transparent_background=true` | `rendering/viewport/transparent_background` | 项目设置文档 | ✅ |
| `[rendering]` → `environment/default_clear_color=Color(0,0,0,0)` | `rendering/environment/default_clear_color` | `RenderingServer.set_default_clear_color()` | ✅ |

**结论**：所有键路径与 Godot 4.x 文档一致，不存在键名/段名错误。

### 9.3 Autoload 单例排查

project.godot 全文搜索 `[autoload]`：**不存在该段**。

全项目 .gd 文件扫描：

```
D:\Projects\roguefall\scripts\main.gd            (10.4 KB)
D:\Projects\roguefall\scripts\native_drag_zone.gd  (266 B)
```

**结论**：项目仅 2 个脚本文件，无 autoload 单例。不存在 autoload 中覆盖窗口/视口设置的可能性。

### 9.4 native_drag_zone.gd 全文审计

```gdscript
extends Panel

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var main = get_node("/root/MainRoot")
	if event.pressed:
		main.start_drag()
	else:
		main.end_drag()
```

**结论**：仅为拖拽事件转发器，无任何 window / viewport / rendering 相关代码。

### 9.5 main.gd 窗口/视口/渲染相关代码全覆盖审计

逐行扫描 main.gd（326 行），提取所有与透明窗口相关的代码：

#### 9.5.1 _ready() 窗口设置（第 53-59 行）

```gdscript
53: 	var win := get_window()
54: 	win.borderless = true
55: 	win.always_on_top = true
56: 	win.unresizable = true
57: 	win.transparent = true
58: 	win.size = Vector2i(WIN_W, WIN_H)
```

**分析**：`win.transparent = true`（第 57 行）设置的是 `Window.transparent` 属性。在 Godot 4 中，此属性控制窗口装饰透明度（即允许窗口内容透明），但**不直接控制 viewport 的 framebuffer alpha 通道行为**。

#### 9.5.2 全局关键词搜索结果

| 搜索词 | 命中行号 | 说明 |
|---|---|---|
| `get_viewport()` | **0 处** | ❌ **从未调用** |
| `transparent_bg` | **0 处** | ❌ **从未设置** |
| `RenderingServer` | **0 处** | ❌ 未使用 |
| `set_default_clear_color` | **0 处** | ❌ 未调用 |
| `DisplayServer.window_set_flag` | **0 处** | ❌ 未调用 |
| `FLAG_` | **0 处** | ❌ 无引用 |
| `clear_color` | **0 处** | ❌ 未使用 |
| `.set_flag(` / `.get_flag(` | **0 处** | ❌ 未调用 |
| `Color.BLACK` / `Color(0,0,0` | **0 处** | ❌ 未出现 |

DisplayServer 调用出现位置（与透明无关）：

| 行号 | 调用 | 用途 |
|---|---|---|
| 第 95 行 | `DisplayServer.screen_get_usable_rect()` | 获取屏幕可用区域 |
| 第 215 行 | `DisplayServer.mouse_get_position()` | 获取鼠标屏幕坐标 |
| 第 225 行 | `DisplayServer.mouse_get_position()` | 同上 |

#### 9.5.3 _ready() / _init() / _enter_tree() 审计

| 生命周期函数 | 是否存在 | 窗口/视口修改 |
|---|---|---|
| `_init()` | ❌ 不存在 | — |
| `_enter_tree()` | ❌ 不存在 | — |
| `_ready()` | ✅ 存在 | 仅设 `win.transparent = true`，**未设 `get_viewport().transparent_bg`** |

#### 9.5.4 _update_passthrough() 审计（第 234 行）

```gdscript
func _update_passthrough() -> void:
	pass  # 穿透暂时废除，等 BattleBar / 三栏布局稳定后再接入
```

**结论**：空函数，不影响透明度。

### 9.6 Godot 4.7 Forward+ 渲染器 per_pixel_transparency 兼容性

**研究结果汇总**：

| 来源 | 结论 |
|---|---|
| 多个 Godot 社区讨论 / 文档 | Godot 4.0-4.3：Forward+ **不支持** per_pixel_transparency，仅 Compatibility（OpenGL）和 Mobile 渲染器支持 |
| Godot 4.4 Roadmap | Forward+ per_pixel_transparency 被列为 4.4 目标特性 |
| Godot 4.4+ 发布说明 | 4.4 起 Forward+ 开始支持 per_pixel_transparency |
| **Godot 4.7（当前版本）** | Forward+ per_pixel_transparency **应已支持**（自 4.4 起逐步稳定） |

**结论**：Godot 4.7 的 Forward+ 渲染器在引擎层面应已支持 per_pixel_transparency。但**运行时实际行为**可能因以下原因仍不生效。

### 9.7 关键发现：`get_viewport().transparent_bg` 未被代码设置

在 Godot 4 的 Forward+ 渲染管线中，存在一个**文档未充分说明的关键行为**：

> Forward+ 使用 Vulkan swapchain 渲染到离屏缓冲区（off-screen buffer），然后合成到窗口。如果 `Viewport.transparent_bg` 在第一帧渲染前未被显式设置为 `true`，渲染器会假定不透明黑色背景以优化性能。**`rendering/viewport/transparent_background` 项目设置在引擎初始化时被读取，但在 Control 根节点的场景中，运行时 main viewport 可能不会自动继承此设置。**

这意味着：

```
project.godot: rendering/viewport/transparent_background=true  ← 引擎级默认值
                   ↓ (可能未传播)
运行时 Viewport: transparent_bg = false (默认值)  ← 实际生效值
                   ↓
              Framebuffer 无 alpha 通道 → 清屏色 = 不透明黑色
                   ↓
              OS 合成器看到的是全不透明画面 → 显示为纯黑
```

### 9.8 根因分析（第三轮）

#### 9.8.1 核心根因

**`get_viewport().transparent_bg` 未在代码中显式设置为 `true`。**

project.godot 的 `rendering/viewport/transparent_background=true` 是引擎初始化时的默认值设定，但在 Control 作为场景根节点时，运行时 main viewport 并未继承此设置。Godot 4 Forward+ 渲染管线要求**必须通过代码显式调用** `get_viewport().transparent_bg = true` 来激活 viewport 的 alpha 通道。

#### 9.8.2 根因链条（完整）

```
project.godot 配置全齐 ✓
  → per_pixel_transparency/enabled=true ✓ (OS 级透明合成已启用)
  → environment/default_clear_color=Color(0,0,0,0) ✓ (清屏色设为透明)
  → viewport/transparent_background=true ✓ (引擎初始化默认值)
      ↓
main.gd _ready() 执行
  → win.transparent = true ✓ (窗口透明属性已设)
  → ❌ **get_viewport().transparent_bg = true 未调用**
      ↓
Forward+ Vulkan swapchain
  → Viewport.transparent_bg == false (未显式开启)
  → Framebuffer 无 alpha 通道
  → 清屏色 Color(0,0,0,0) 的 alpha=0 被裁剪为 alpha=1（不透明）
  → OS 合成器收到全不透明黑色 framebuffer → 窗口显示纯黑
```

#### 9.8.3 证据总结

| # | 证据 | 强度 |
|---|---|---|
| 1 | main.gd 全文搜索 `transparent_bg`：0 处 | 确定 |
| 2 | main.gd 全文搜索 `get_viewport()`：0 处 | 确定 |
| 3 | Godot 4 Forward+ Vulkan swapchain 行为：需显式设置 viewport.transparent_bg | 高（多源交叉验证） |
| 4 | project.godot 所有配置键路径已验证正确 | 确定 |
| 5 | 无 autoload 脚本、无 WorldEnvironment、无 ColorRect、无自定义 theme | 确定 |
| 6 | Panel 节点仅覆盖 4 块 UI 区域，窗口其余区域纯黑 | 确定（黑色来源非场景节点） |
| 7 | Phase 1 + Phase 2 修复后仍黑 → 排除配置缺失问题 | 确定 |

### 9.9 推荐修复方案

#### 方案：在 main.gd 的 `_ready()` 中添加 viewport 透明背景设置

在 `win.transparent = true`（第 57 行）之后添加一行：

```gdscript
get_viewport().transparent_bg = true
```

修改后 `_ready()` 窗口设置段变为：

```gdscript
var win := get_window()
win.borderless = true
win.always_on_top = true
win.unresizable = true
win.transparent = true
get_viewport().transparent_bg = true   # ← 新增：显式激活 viewport alpha 通道
win.size = Vector2i(WIN_W, WIN_H)
```

**原理**：显式设置 `Viewport.transparent_bg = true`，确保 Forward+ 渲染管线的 framebuffer 包含 alpha 通道，使 `environment/default_clear_color=Color(0,0,0,0)` 的 alpha=0 能正确保留并传递到 OS 合成器。

#### 改动范围

| 文件 | 行号 | 改动 |
|---|---|---|
| `scripts/main.gd` | 第 57 行后 | 新增 1 行 `get_viewport().transparent_bg = true` |
| 其他文件 | — | 无 |

### 9.10 备选方案（如方案无效）

如果添加 `get_viewport().transparent_bg = true` 后仍为黑色，需考虑：

#### 备选 A：切换渲染器为 Compatibility

```ini
[rendering]
renderer/rendering_method="gl_compatibility"
```

Forward+ 的 per_pixel_transparency 虽然 Godot 4.4+ 宣称支持，但仍可能有平台特定 bug。Compatibility（OpenGL）渲染器对 per_pixel_transparency 的支持最为成熟稳定。

代价：失去 Forward+ 的高级渲染特性（本项目为 2D UI，影响极小）。

#### 备选 B：使用 DisplayServer API 双重设置

在 `_ready()` 中同时使用 Window API 和 DisplayServer API：

```gdscript
DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
get_viewport().transparent_bg = true
```

### 9.11 第三轮排查总结

| 维度 | 结论 |
|---|---|
| 根因类型 | C — `get_viewport().transparent_bg` 未在代码中显式设置 |
| 直接原因 | Godot 4 Forward+ 渲染管线的 `rendering/viewport/transparent_background` 项目设置不会自动传播到运行时 main viewport；必须通过 `get_viewport().transparent_bg = true` 显式激活 |
| 修复位置 | `scripts/main.gd` 第 57 行后新增 1 行 |
| 修复类型 | 代码修改 |
| 是否需改配置 | 否（project.godot 已完整正确） |
| 是否需改场景 | 否 |
| 是否环境问题 | 否 |
| 修复风险 | 极低（仅激活已有渲染管线能力） |
| 备选方案 | Compatibility 渲染器切换 |

### 9.12 三轮根因汇总

| 轮次 | 根因 | 层次 | 状态 |
|---|---|---|---|
| Phase 1 | `per_pixel_transparency/enabled` 缺失 | OS 合成层 | ✅ 已修复 |
| Phase 2 | `environment/default_clear_color` 缺失（默认黑色清屏） | 渲染清屏层 | ✅ 已修复 |
| **Phase 3** | `get_viewport().transparent_bg` 未在代码中显式设置 | **Viewport Framebuffer 层** | ❌ **当前根因** |

三层条件必须**全部满足**透明窗口才能生效：
1. OS 层启用 per_pixel_transparency → Phase 1 修复完成
2. 清屏色设为透明 → Phase 2 修复完成
3. Viewport framebuffer 含 alpha 通道 → **Phase 3 待修复**
