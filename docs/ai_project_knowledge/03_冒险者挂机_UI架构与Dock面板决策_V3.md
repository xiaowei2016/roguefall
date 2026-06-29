# 冒险者挂机 UI架构与Dock面板决策 V3

> 项目名：冒险者挂机 | 引擎：Godot 4.7 | 路径：D:\Projects\roguefall
> 本文件描述**当前实际代码实现**的 UI 架构，已按 src:main.gd + main.tscn 逐行核对。
> 整合原Ui节点架构.txt的10条硬性UI铁则

---

## 1. 实际节点树结构（src: main.tscn）

```text
MainRoot (Control, 1440×720, mouse_filter=IGNORE)
├── PixelPassthrough (Node, DesktopPixelPassthrough.cs, Win32像素穿透)
└── PanelRoot (Control, mouse_filter=PASS)
    ├── LeftPanel (Control, 宽度352, mouse_filter=PASS)
    │   ├── Panel (dragzone, native_drag_zone.gd)
    │   ├── WarehouseContent (仓库)
    │   ├── PetContent (宠物)
    │   ├── CodexContent (图鉴)
    │   └── MapContent (地图)
    ├── CenterPanel (Control, 宽度720, mouse_filter=PASS)
    │   ├── CenterPanelBack (TextureRect, 品红背景去底png)
    │   ├── Panel (dragzone, transparent style)
    │   └── CenterLayoutRoot
    │       ├── LeftArea (CharEquipArea + AttrScroll)
    │       ├── RightArea (BagTitle + CategoryTabs + BagScroll/BagGrid)
    │       └── BottomArea (LeftButtons: 仓库/宠物/图鉴/地图 + RightButtons: 设置/洗练/详情)
    ├── RightPanel (Control, 宽度352, mouse_filter=PASS)
    │   ├── Panel (dragzone)
    │   ├── SettingsContent (设置)
    │   ├── RerollContent (洗练)
    │   └── DetailContent (详情)
    └── BattleBar (Control, 720×180, mouse_filter=PASS)
        ├── GrasslandStage2D (战斗场景实例)
        ├── Panel (dragzone, transparent style)
        │   ├── LvLabel, HpLabel, ExpLabel, GoldLabel
        └── Button (背包, toggle CenterPanel)
```

**关键简化**：所有布局/翻转/让位/拖动逻辑集中在 `main.gd` 单文件中。没有 WindowShell / DockLayer / DockLayoutController 等分拆节点。穿透由 `DesktopPixelPassthrough.cs`（Win32 像素级）独立处理，Godot 层的 `_update_passthrough()` 已废除。

---

## 2. 默认显示状态

| 节点 | 默认状态 | 说明 |
|---|---|---|
| BattleBar | visible=true | 常驻挂机条，720×180 |
| CenterPanel | visible=false | 从 BattleBar.Button(背包) toggle 打开 |
| LeftPanel | visible=false | 随 CenterPanel 打开，由 LeftButtons 切换内容 |
| RightPanel | visible=false | 随 CenterPanel 打开，由 RightButtons 切换内容 |
| 各 Content | visible=false | 按对应按钮切换显示，互斥 |

---

## 3. 打开/关闭交互逻辑（src: main.gd _on_bag / _on_left_button / _on_right_button）

```
BattleBar 始终显示。
CenterPanel 从 BattleBar.Button("背包") toggle 打开/关闭。
关闭 CenterPanel 时 LeftPanel/RightPanel 也关闭（_left_content/_right_content 归 NONE）。
LeftPanel 内容按键：仓库/宠物/图鉴/地图，已选中再点取消选中。
RightPanel 内容按键：设置/洗练/详情，已选中再点取消选中。
单独的内容切换不影响 CenterPanel 可见性。
```

---

## 4. 固定尺寸常量（src: main.gd const 区，hash: 0fd34a8）

| 常量名 | 值 | 含义 |
|---|---|---|
| WIN_W | 1440 | 主窗口宽度 |
| WIN_H | 718 | 主窗口高度（PANEL_H + GAP + BATTLE_H） |
| BATTLE_H | 180 | BattleBar 高度 |
| PANEL_H | 530 | 面板组高度 |
| PW | 352 | 左/右面板宽度 |
| CW | 720 | CenterPanel / BattleBar 宽度 |
| EDGE_MARGIN | 16 | 屏幕边缘留白 |
| GAP | 8 | 面板间距 |
| BATTLE_REST_X | 360 | 窗口原点相对 BattleBar 锚点的 X 偏移 |
| FLIP_BOT | 538 | BattleBar 初始 Y 偏移（_ready 推导用） |
| FLIP_HYSTERESIS | 48 | 翻转滞后阈值（拖拽时防抖用） |

**窗口原点计算**：`win_x = BattleBar锚点X - BATTLE_REST_X`。面板组水平位置以 BattleBar 屏幕 X 为中心对齐，不是固定锚点。

---

## 5. 翻转让位穿透机制（src: main.gd _do_layout / DesktopPixelPassthrough.cs）

### 5.1 翻转（Flip）— 面板上下位置自动判定

BattleBar 可自由拖拽。面板组（LeftPanel + CenterPanel + RightPanel）根据 BattleBar 屏幕坐标和可用空间，自动决定放在 BattleBar 上方还是下方：

- **判定逻辑**：比较 BattleBar 上方可用空间 vs 下方可用空间
- **非拖拽时**：`flipped = space_above < space_below`（哪边空间大放哪边）
- **拖拽时**：引入 `FLIP_HYSTERESIS=48px` 滞后，避免在临界点频繁翻转
  - 如果上次是 flipped（面板在下），需要下方比上方大 48px 以上才切回上方
  - 如果上次是非 flipped（面板在上），需要上方比下方大 48px 以上才切到下方
- **flipped=true**：`panel_sy = BattleBar.bottom + GAP`（面板在 BattleBar 下方）
- **flipped=false**：`panel_sy = BattleBar.top - PANEL_H - GAP`（面板在 BattleBar 上方）
- 窗口原点也随翻转调整：flipped 时 win_y = BattleBar.top；非 flipped 时 win_y = BattleBar.top - FLIP_BOT

### 5.2 让位（Panel Shift）— 面板组水平避让屏幕边缘

面板组（含左右面板）整体宽度可能超出屏幕。当面板组左/右边缘超出 `EDGE_MARGIN=16px` 时，面板组整体水平平移（BattleBar 不参与平移）：

- `panel_shift = screen_min - panel_group_left`（左边溢出 → 向右让）
- `panel_shift = screen_max - panel_group_right`（右边溢出 → 向左让）
- 平移后所有面板 screen-space X 坐标统一 + panel_shift

### 5.3 穿透（Passthrough）— 两层实现

**活跃层：像素级穿透（DesktopPixelPassthrough.cs）**
- 通过 Win32 `SetWindowLongPtr` 控制 `WS_EX_TRANSPARENT` 窗口样式
- `_Process` 每帧读取鼠标下像素 alpha：alpha <= 0.1 则穿透，alpha > 0.1 则拦截
- 鼠标在窗口外 → 强制穿透
- 日志节流：仅在 exstyle 实际切换时输出 SWITCH 日志

**已废除层：区域穿透（main.gd _update_passthrough）**
- `_update_passthrough()` 函数体为 `pass`
- 注释："穿透暂时废除，等 BattleBar / 三栏布局稳定后再接入"
- 计划用途：Godot 层通过 `DisplayServer.window_set_mouse_passthrough(regions)` 管理可交互区域多边形穿透
- 当前由像素级穿透完全替代，效果优于区域穿透

---

## 6. 职责边界定义（当前实际架构）

| 组件 | 实现位置 | 职责 |
|---|---|---|
| main.gd | scripts/main.gd | 窗口属性设置、BattleBar 拖拽转发、全局面板布局计算（翻转+让位）、面板可见性状态机、持久化、按钮事件路由 |
| DesktopPixelPassthrough.cs | scripts/DesktopPixelPassthrough.cs | Win32 像素级鼠标穿透 |
| native_drag_zone.gd | scripts/native_drag_zone.gd | 转发鼠标拖拽事件到 main.gd 的 start_drag/end_drag |
| 各 Content 节点 | main.tscn 内置 | 自身内容展示（当前为占位 Label） |

**当前没有独立存在的节点/脚本**：WindowShell、DockLayoutController、InputRegionManager、DockLayer、DockHost。所有逻辑在 `main.gd` 中内聚管理。未来如需拆分，必须先从 main.gd 提取逻辑并验证后替换。

---

## 7. 脚本文件清单（当前实际存在的脚本）

| 脚本 | 路径 | 职责 |
|---|---|---|
| main.gd | scripts/main.gd | 窗口初始化、布局计算（翻转/让位）、面板状态机、拖拽中转、持久化、按钮事件 |
| DesktopPixelPassthrough.cs | scripts/DesktopPixelPassthrough.cs | Win32 像素穿透（WS_EX_TRANSPARENT 切换） |
| native_drag_zone.gd | scripts/native_drag_zone.gd | 转发拖拽事件到 main |
| game_data.gd | scripts/game_data.gd | 全局游戏数据单例（level/hp/exp/gold/attack/defense） |
| player_actor.gd | scripts/player_actor.gd | 玩家角色（占位） |
| dummy_enemy.gd | scripts/dummy_enemy.gd | 假怪物（占位） |
| grassland_parallax.gd | scripts/grassland_parallax.gd | 草原背景视差 |

---

## 8. F5验收标准

1. 启动看到 BattleBar 720×180，窗口 1440×718 透明桌面
2. 拖动 BattleBar 流畅无闪烁，面板跟随翻转
3. 点击背包按钮打开 CenterPanel（720×530），三栏并排
4. 点击仓库/宠物/图鉴/地图按钮切换左侧内容
5. 点击设置/洗练/详情按钮切换右侧内容
6. 三栏超出屏幕时自动让位平移
7. BattleBar 拖到屏幕下半区时面板自动翻到上方，拖回上半区翻到下方
8. 透明区域（窗口内无控件区域）鼠标穿透到桌面
9. 关闭 CenterPanel 时 LeftPanel/RightPanel 同时关闭
10. 窗口尺寸始终 1440×718 不变

---

## 9. 窗口系统冻结常量（src: main.gd, hash: 0fd34a8）

以下 const 修改必须经过总控确认：

| 常量 | 值 | 说明 |
|---|---|---|
| WIN_W | 1440 | 主窗口宽度 |
| WIN_H | 718 | 主窗口高度 |
| BATTLE_H | 180 | BattleBar 高度 |
| PANEL_H | 530 | 面板组高度 |
| PW | 352 | 左/右面板宽度 |
| CW | 720 | CenterPanel 宽度 |
| EDGE_MARGIN | 16 | 屏幕边缘留白 |
| GAP | 8 | 面板间距 |
| FLIP_HYSTERESIS | 48 | 翻转滞后阈值 |
| BATTLE_REST_X | 360 | 窗口原点偏移 |

---

## 10. 透明窗口配置

Godot 4.7 项目设置：
- display/window/size/viewport_width = 1440
- display/window/size/viewport_height = 720
- display/window/size/transparent = true
- display/window/per_pixel_transparency/enabled = true

Win32 像素穿透在 `_Ready` 中设置 `WS_EX_LAYERED` 样式，运行时按像素 alpha 动态切换 `WS_EX_TRANSPARENT`。

---

## 附录：UI节点硬性铁则（10条）

> 以下规则整合自原Ui节点架构.txt，对所有UI开发具有最高约束力。

1. **三层节点封顶**：任意UI控件树深度不超过 Control → 容器 → 原子组件 三层
2. **独立tscn预制文件**：每个UI面板必须是独立.tscn文件，禁止代码new出面板结构
3. **全局Theme主题**：所有UI控件统一使用项目Theme资源（res://assets/ui/theme/roguefall_theme.tres），禁止面板各自定义StyleBox
4. **禁止多层嵌套**：Panel → Panel → Panel → ... 禁止，必须扁平化为 Panel → VBox/HBox → 原子控件
5. **自由拖拽位置**：BattleBar默认居中但可拖拽，程序启动时居中放置
6. **MainRoot透明**：MainRoot自身 mouse_filter=IGNORE，PanelRoot 和子控件设 mouse_filter=PASS
7. **窗口透明**：通过Godot项目设置实现透明，像素穿透由 DesktopPixelPassthrough.cs 的 Win32 API 实现
8. **三层结构**：所有UI Panel必须使用 Background(Base) → Content(Vbox/Hbox) → Interaction(Button/Label) 三层结构
9. **面板固定关系**：BattleBar常驻显示，其他面板toggle显示，面板之间通过信号通信
10. **禁止工具脚本污染**：临时Debug/HUD/控制台脚本禁止留在最终.tscn中
