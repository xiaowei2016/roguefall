<!--
冒险者挂机 GPT 项目知识文件 V2 完整版
固定信息：
- 项目名：冒险者挂机
- 引擎版本：Godot 4.7
- Godot 4.7 固定目录：D:\Projects
- 推荐 Godot 4.7 可执行文件：D:\Projects\Godot_v4.7-stable_win64.exe
- 项目固定路径：D:\Projects\roguefall
- 项目知识文档固定目录：D:\Projects\roguefall\docs\ai_project_knowledge
- UI 架构：1440×720 透明逻辑画布 + 常驻 BattleWidget 挂机条 + Dock 管理面板
- 旧实现废弃：旧 BattleStrip / layout_shell 直接控制全局窗口、穿透、拖动和三栏绑定；新架构由 WindowShell、DockLayoutController、InputRegionManager 统一管理
-->

# 冒险者挂机 UI架构、透明窗口与Dock面板决策 V2

> 来源：合并自原 03_UI架构、04_透明窗口教程、20_Dock架构决策

---

## 第一部分：UI 核心架构

### 1.1 架构结论

MainRoot 基准尺寸：1440×720。

```text
MainRoot (Control, 1440×720)
└── ContentContainer (Control, 1440×720)
    ├── WindowShell (Control)
    │   - 负责窗口大小/位置
    ├── TransparentCanvas (ColorRect)
    │   - 背景透明画布
    ├── WindowDragLayer (Control)
    │   - 处理窗口拖动
    ├── InputRegionManager (Control)
    │   - 统一鼠标穿透区域计算
    ├── DockLayer (Control)
    │   ├── LeftDockHost (Control)          ← 左侧扩展容器，内容由 CenterPanel 按钮决定
    │   │   └── [动态内容: 仓库/宠物/图鉴/地图]
    │   ├── CenterDockHost (Control)        ← 核心管理界面
    │   │   └── CenterPanel
    │   │       ├── 左半：角色/属性/装备穿戴
    │   │       └── 右半：背包
    │   └── RightDockHost (Control)         ← 右侧扩展容器，内容由 CenterPanel 按钮决定
    │       └── [动态内容: 设置/洗练/详情]
    └── BattleWidget (Control)
        ├── Background
        ├── TitleLabel
        ├── HpBar
        ├── ExpBar
        ├── GoldLabel
        └── BagButton
```

### 1.2 默认显示状态

```text
BattleWidget.visible     = true
BattleBar.visible        = true
CenterPanel.visible      = false
LeftPanel.visible        = false
RightPanel.visible       = false
```

默认只显示 BattleWidget / BattleBar 常驻挂机条。左右栏是空容器，无默认内容。

### 1.3 打开/关闭交互逻辑（Dock 容器切换 — 已冻结）

> **本交互逻辑已冻结，禁止修改。** 详见 [第四部分：Dock 面板容器切换逻辑冻结规范](#第四部分dock-面板容器切换逻辑冻结规范)。

**BattleBar 唯一入口：**

点击 BattleBar.BagButton：
- CenterPanel 隐藏时 → 显示 CenterPanel
- CenterPanel 显示时 → 关闭 CenterPanel，同时关闭 LeftPanel 和 RightPanel（全部归 NONE）
- BattleBar 始终保持显示

**CenterPanel 是核心管理界面：**
- 左半：角色/属性/装备穿戴
- 右半：背包

**左栏按钮（在 CenterPanel 内）：仓库 / 宠物 / 图鉴 / 地图**

**右栏按钮（在 CenterPanel 内）：设置 / 洗练 / 详情**

**同侧按钮点击规则：**
- 同一个按钮再次点击 → 关闭该侧栏（归 NONE）
- 其他同侧按钮点击 → 只切换内容，不关闭该侧栏

**关闭 CenterPanel 时：**
- LeftPanel 和 RightPanel 必须同时关闭并归 NONE

**禁止：**
- 把左右栏写成自带默认内容的固定页面
- LeftPanel 不是仓库，RightPanel 不是设置
- 恢复 TabBar / PageHost 全屏页面切换

### 1.4 固定尺寸（冻结）

> **本布局已冻结，禁止修改。** 所有锚点以 1440×720 设计基准换算，零硬编码。

```text
Canvas: 1440×720

BattleWidget:
  w=720, h=180
  anchor_left=0.25, anchor_right=0.75
  anchor_top=0.75, anchor_bottom=1.0（贴底，零边距）

三栏高度: 530（anchor_top=0.0, anchor_bottom=0.736111）
三栏间 gap_x=8, gap_y=0
四边 margin=0，左右贴边

LeftDockHost:
  w=352
  anchor_left=0.0, anchor_right=0.244444

CenterDockHost:
  w=720
  anchor_left=0.25, anchor_right=0.75

RightDockHost:
  w=352
  anchor_left=0.755556, anchor_right=1.0
```

### 1.5 禁止硬编码规则（V2.1 新增）

所有 UI 布局必须使用锚点比例（anchor）而非硬编码像素（offset），确保在任意分辨率/DPI 下自动适配。

**禁止：**
- MainRoot 或任何容器节点使用 `offset_right` / `offset_bottom` 写死像素尺寸
- 使用 `rect_position` / `rect_size` 写死坐标和尺寸
- 在脚本中用 `Vector2(1440, 720)` 等固定像素值设置节点尺寸
- 依赖 `get_viewport().size` 在 _ready 中一次性计算后写死

**只允许：**
- anchor 比例定义位置和尺寸（如 `anchor_right = 0.233333` 表示 23.3333% 宽度）
- 面板间 gap 用 anchor 间隙表达（如两栏锚点之间留 8/1440 的比例间隙）
- 四边 margin=0，面板从锚点边界直接定位

**比例基准：**
- 所有锚点值以 `1440×720` 为设计基准画布换算
- 例如：352px 面板 = 352/1440 ≈ 0.244444；720px 面板 = 720/1440 = 0.5
- 8px gap = 8/1440 ≈ 0.005556

### 1.6 翻转与让位规则

> **已废弃：本节描述的"面板在上、空间不足翻转、左右让位"旧方案已弃用。** 该方案基于 window-space 反推模型，存在 BattleBar 锚点被面板反写、翻转闪烁等缺陷。

当前正确方案见 [窗口系统冻结规范（0fd34a8）](#窗口系统冻结规范0fd34a8)。

### 1.7 职责边界

允许：
- BattleWidget 发出 open_bag 请求
- BagPanel 发出 open_left_panel / open_right_panel 请求
- DockLayoutController 统一计算位置
- InputRegionManager 统一计算鼠标穿透区域

禁止：
- BattleWidget 直接控制全局窗口尺寸
- BattleWidget 直接调用 DisplayServer.window_set_mouse_passthrough
- CenterPanel / LeftPanel / RightPanel 自己计算全局窗口布局
- 复制旧工程 layout_shell.gd
- 恢复旧 BattleStrip 直接控制穿透
- 使用全屏 PageHost 替换 BattleWidget
- 使用左侧全局 TabBar 切换整页
- 把左右栏写成自带默认内容的固定页面（LeftPanel 不是仓库，RightPanel 不是设置）

### 1.8 脚本职责

| 脚本 | 职责 |
|---|---|
| WindowShell | 窗口创建/尺寸/置顶/透明属性 |
| DockLayoutController | 面板打开关闭/位置计算/翻转让位 |
| InputRegionManager | 统一鼠标穿透区域计算 |
| BattleWidget | 常驻挂机条UI/按钮事件发送 |
| BattleBar | 挂机条核心控件/背包按钮入口 |
| CenterPanel | 核心管理界面：左半（角色/属性/装备穿戴）+ 右半（背包）/ 左右栏按钮 |
| LeftPanel | 左侧扩展容器，内容由 CenterPanel 按钮决定 |
| RightPanel | 右侧扩展容器，内容由 CenterPanel 按钮决定 |

### 1.9 交互验收标准

F5 验收顺序：

1. 默认只显示 BattleWidget / BattleBar
2. 点击背包 → 显示与 BattleBar 同宽的 CenterPanel（左半角色属性 + 右半背包）
3. 点击 CenterPanel 左栏按钮（仓库/宠物/图鉴/地图）→ 对应内容在 LeftPanel 显示
4. 点击 CenterPanel 右栏按钮（设置/洗练/详情）→ 对应内容在 RightPanel 显示
5. 同侧按钮再次点击 → 关闭该侧栏
6. 其他同侧按钮点击 → 只切换内容，不关闭该侧栏
7. 再次点击背包或关闭 CenterPanel → LeftPanel 和 RightPanel 同时关闭归 NONE
8. 拖动 BattleWidget 到左侧 → 面板不出界并自动让位
9. 拖动 BattleWidget 到右侧 → 面板不出界并自动让位
10. 拖动 BattleWidget 到顶部 → 面板自动翻转到下方
11. BattleWidget / BattleBar 始终可见
12. 透明空白区域由 InputRegionManager 统一穿透

### 1.10 窗口系统冻结规范（0fd34a8）

> 窗口系统已于 2026-06-26 冻结，稳定 commit：origin/master = **0fd34a8**。
> 此后禁止以任何形式修改窗口核心数学。

**架构总则：**

- BattleBar 是唯一拖拽锚点，所有面板跟随它定位。
- 布局模型：screen-space + virtual frame。
- 计算顺序：先在屏幕坐标计算 BattleBar 和面板位置 → 换算成 Godot local position。
- window origin 使用 virtual frame（基于 BattleBar 锚点与 BATTLE_REST_X=360 反算），不使用 union_rect.position。

**BattleBar 位置约束：**

- 未贴边时 BattleBar local 默认 x=360。
- 贴左/右边缘时 BattleBar local 允许临时变成 0~720。
- 离开边缘后自然回到 x=360，**禁止 snap 强制吸回**。

**面板约束：**

- CenterPanel / LeftPanel / RightPanel 只能跟随 BattleBar，**不能反写 BattleBar 锚点**。
- 隐藏面板不参与布局、不占位、不参与 bounds。
- mode=0（仅 BattleBar 可见）时，不参与面板翻转。

**翻转规则（仅当有面板可见时生效）：**

- 上下翻转使用 FLIP_HYSTERESIS=48（96px 死区），消除过中线翻转闪烁。
- window_y 必须 clamp 到屏幕安全范围，禁止出现负数窗口大跳。

**日志约束：**

- 日志节流只影响 print，不影响布局逻辑。

### 1.11 后续禁止修改项

> 以下内容已被冻结，**绝对禁止**再次修改、恢复、或在任何新代码中引用。

| 禁止项 | 说明 |
|---|---|
| `_battle_local_x` 变量 | 旧局部坐标存储，已删除。位置由 BattleBar 锚点唯一决定 |
| `_snap_battlebar_to_center()` | 旧强制吸回函数，已删除。不依赖 snap 归位 |
| CenterPanel 反写锚点 | 面板永远不能修改 BattleBar 的锚点坐标 |
| `idle` / `end_drag` 中强制归位 | 旧逻辑，会导致 BattleBar 被吸回 CenterPanel.x |
| `union_rect.position` 决定窗口位置 | 旧方案，会导致 battle_local.x 恒为 0 |
| window-space 反推模型 | 旧 `_do_layout` 方式，已被 screen-space 模型替代 |
| 旧 BattleStrip 直接控制全局穿透 | 旧架构，已被 InputRegionManager 统一管理 |
| 旧 layout_shell 三栏绑定 | 旧架构，已被 DockLayoutController 替代 |

### 1.12 允许修改范围

以下内容仍可自由修改，不受窗口冻结限制：

- 面板内部内容：背包格子布局、装备槽排列、属性卡片样式
- 按钮外观：颜色、圆角、图标替换
- UI 文案：标签文字、提示信息
- 非核心视觉：背景装饰、边角花纹、高光效果
- 面板内容控件的 .tscn 结构和 .gd 数据绑定逻辑

---

## 第二部分：透明窗口与鼠标穿透实现

### 2.1 目标

实现 Godot 4.7 桌面挂件游戏窗口：透明背景 + 游戏 UI 可见 + 空白区域鼠标穿透到底层桌面。

### 2.2 project.godot 配置

```ini
[display]
window/size/viewport_width=1440
window/size/viewport_height=720
window/size/transparent=true
window/per_pixel_transparency/enabled=true
window/size/borderless=false

[rendering]
renderer/rendering_method=gl_compatibility
environment/default_clear_color=Color(0, 0, 0, 0)
```

### 2.3 InputRegionManager 设计

核心原则：所有鼠标穿透逻辑集中在 InputRegionManager，不分散到各面板。

```gdscript
# InputRegionManager.gd - 核心结构
extends Control

func refresh_passthrough():
    # 遍历所有可见UI子节点，计算非透明区域
    # 将非透明区域合集传给 DisplayServer
    var regions: Array[Rect2] = []
    for child in get_parent().get_children():
        if child is Control and child.visible and not (child is TransparentCanvas):
            var global_rect = child.get_global_rect()
            regions.append(global_rect)
    # 传给DisplayServer
    DisplayServer.window_set_mouse_passthrough(regions)
```

### 2.4 推荐最小实现代码

```gdscript
# main.gd 入口
extends Node

func _ready():
    # 设置透明
    get_window().transparent = true
    # 初始化穿透区域
    $WindowShell/InputRegionManager.refresh_passthrough()

# WindowShell.gd
extends Control

func _ready():
    var window = get_window()
    window.size = Vector2(1440, 720)
    window.transparent = true
    window.borderless = false
    window.always_on_top = true
```

### 2.5 穿透刷新时机

以下事件触发 InputRegionManager.refresh_passthrough()：
- 面板打开/关闭
- 面板拖动结束
- 窗口大小变化
- BattleWidget 位置变化

### 2.6 禁止事项

- 禁止各面板脚本自行调用 DisplayServer.window_set_mouse_passthrough
- 禁止在 BattleWidget 中写入穿透逻辑
- 禁止使用旧工程中分散的穿透代码片段
- 透明窗口不能做成完全不可交互的空壳

---

## 第三部分：与旧架构的区别

废弃的旧实现方式：
- 旧 BattleStrip 直接控制全局窗口
- 旧 BattleStrip 直接控制全局穿透
- 旧 layout_shell 把三栏和战斗条强绑定
- 页面脚本各自改窗口穿透和窗口大小
- 旧 TabBar + PageHost 全屏页面切换

正确方式：
- WindowShell + DockLayoutController + InputRegionManager 统一管理
- BattleWidget 只作为常驻子控件，不控制全局
- 面板只发请求，不自己计算全局布局

---

## 第四部分：Dock 面板容器切换逻辑冻结规范

> 本章节已于 2026-06-26 冻结。冻结原因：Dock 面板容器切换逻辑已通过验证，禁止后续误解或恢复旧架构。

### 4.1 核心结论（12 条固化）

1. 默认只显示 BattleWidget / BattleBar。
2. BattleBar 只负责通过【背包】打开 CenterPanel。
3. CenterPanel 固定是核心管理界面：左半（角色/属性/装备穿戴）+ 右半（背包）。
4. LeftPanel 不是仓库，LeftPanel 只是左侧扩展容器。
5. RightPanel 不是设置，RightPanel 只是右侧扩展容器。
6. 左右栏内容必须由 CenterPanel 内按钮明确打开。
7. 左栏按钮：仓库 / 宠物 / 图鉴 / 地图。
8. 右栏按钮：设置 / 洗练 / 详情。
9. 同侧按钮点击规则：同一个按钮再次点击关闭该栏；其他同侧按钮点击时只切换内容，不关闭该栏。
10. 关闭 CenterPanel 时，LeftPanel 和 RightPanel 必须同时关闭并归 NONE。
11. 禁止把左右栏写成自带默认内容的固定页面。
12. 禁止恢复 TabBar / PageHost。

### 4.2 状态机（禁止修改）

```text
              ┌─────────────────┐
              │  NONE（默认）    │
              │  CenterPanel=NONE│
              │  LeftPanel=NONE  │
              │  RightPanel=NONE │
              └───────┬─────────┘
                      │ BattleBar.背包按钮
                      ▼
              ┌─────────────────┐
              │  CENTER_OPEN     │
              │  CenterPanel 显示 │
              │  LeftPanel=NONE  │
              │  RightPanel=NONE │
              └───────┬─────────┘
                      │
          ┌───────────┼───────────┐
          │ 左栏按钮   │           │ 右栏按钮
          ▼           │           ▼
  ┌──────────────┐   │   ┌──────────────┐
  │ LEFT_OPEN    │   │   │ RIGHT_OPEN   │
  │ LeftPanel    │   │   │ RightPanel   │
  │ 显示对应内容  │   │   │ 显示对应内容  │
  └──────┬───────┘   │   └──────┬───────┘
         │           │          │
         │ 同按钮再次 │          │ 同按钮再次
         ▼           │          ▼
    LeftPanel=NONE   │     RightPanel=NONE
         │           │          │
         │ 其他同侧   │          │ 其他同侧
         ▼           │          ▼
   切换内容（不关栏） │    切换内容（不关栏）
                      │
          ┌───────────┘
          │ BattleBar.背包按钮 或 关闭 CenterPanel
          ▼
    CenterPanel + LeftPanel + RightPanel 全部归 NONE
```

### 4.3 后续禁止修改项（Dock 容器）

| 禁止项 | 说明 |
|---|---|
| LeftPanel 默认显示仓库 | LeftPanel 是空容器，内容必须由 CenterPanel 按钮明确打开 |
| RightPanel 默认显示设置 | RightPanel 是空容器，内容必须由 CenterPanel 按钮明确打开 |
| 左右栏写成固定页面 | 左右栏不能自带默认内容，禁止在 tscn 中预置子面板 |
| 恢复 TabBar 切换整页 | 旧全屏 PageHost + TabBar 架构已彻底废弃 |
| CenterPanel 关闭时保留左右栏 | 关闭 CenterPanel 必须同时关闭左右栏 |
| 同侧按钮切换时关闭该栏 | 同侧按钮切换只换内容，不关栏；仅同按钮再次点击才关栏 |
| WarehousePanel 固定绑定 LeftDockHost | 仓库只是左栏按钮的一种内容，不是固定属性 |
| SettingsPanel 固定绑定 RightDockHost | 设置只是右栏按钮的一种内容，不是固定属性 |

### 4.4 允许修改范围

以下内容仍可自由修改，不受 Dock 冻结限制：

- 左栏按钮的具体内容实现：仓库 UI、宠物展示、图鉴列表、地图选择
- 右栏按钮的具体内容实现：设置项、洗练界面、详情面板
- CenterPanel 内部布局细节（左半角色属性排版、右半背包格子排列）
- 按钮样式、颜色、图标
- 各内容面板的 .tscn 结构和 .gd 数据绑定逻辑
