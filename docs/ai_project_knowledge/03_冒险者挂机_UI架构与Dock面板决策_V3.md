# 冒险者挂机 UI架构与Dock面板决策 V3

> 项目名：冒险者挂机 | 引擎：Godot 4.7 | 路径：D:\Projects\roguefall
> 整合原Ui节点架构.txt的10条硬性UI铁则

---

## 1. 正确节点树结构

```text
MainRoot (Control, 1440×720)
├── WindowShell (统一管理窗口尺寸/拖动/透明/穿透)
│   ├── TransparentCanvas
│   ├── WindowDragLayer
│   ├── InputRegionManager
│   └── DockLayer
│       ├── LeftDockHost
│       │   ├── WarehousePanel
│       │   └── HeroPanel
│       ├── CenterDockHost
│       │   └── BagPanel
│       └── RightDockHost
│           ├── MapPanel
│           └── SettingsPanel
└── BattleWidget (常驻挂机条，非Dock子节点)
    ├── TopInfoBar
    ├── HpBar
    ├── ExpBar
    ├── GoldLabel
    └── BagButton
```

---

## 2. 默认显示状态

| 节点 | 默认状态 | 说明 |
|---|---|---|
| WindowShell | visible=true | 始终显示 |
| BattleWidget | visible=true | 常驻挂机条 |
| BagPanel | visible=false | 从BattleWidget.BagButton打开 |
| LeftDockHost | visible=false | 从BagPanel左侧打开 |
| RightDockHost | visible=false | 从BagPanel右侧打开 |
| WarehousePanel | visible=false | LeftDockHost子面板 |
| HeroPanel | visible=false | LeftDockHost子面板 |
| MapPanel | visible=false | RightDockHost子面板 |
| SettingsPanel | visible=false | RightDockHost子面板 |

---

## 3. 打开/关闭交互逻辑

```
BattleWidget 始终显示。
BagPanel 从 BattleWidget.BagButton toggle 打开/关闭。
WarehousePanel/HeroPanel 从 BagPanel 左侧 Dock 按钮打开。
MapPanel/SettingsPanel 从 BagPanel 右侧 Dock 按钮打开。
```

关闭规则：关闭BagPanel时左右Dock面板也关闭。单独的Dock面板关闭不影响其他面板。

---

## 4. 固定尺寸与冻结值（hash: 0fd34a8，严禁修改）

| 元素 | 固定值 |
|---|---|
| 主窗口 | 1440×720 |
| BattleWidget | 720×180 |
| BagPanel宽度 | 720（与BattleWidget一致） |
| LeftDockHost宽度 | 360 |
| RightDockHost宽度 | 360 |
| 左侧面板起始X | 16 |
| 中心面板起始X | 360 |
| 右侧面板起始X | 1088 |

禁止硬编码这些数值到各面板脚本中。所有布局由DockLayoutController统一计算。

---

## 5. 翻转让位规则（已简化）

当前版本不使用翻转让位。左右两侧面板同时打开时使用默认三栏布局。如需调整，由DockLayoutController统一处理。

---

## 6. 职责边界定义

| 组件 | 职责 |
|---|---|
| WindowShell | 窗口尺寸、拖动、透明标志 |
| DockLayoutController | 面板布局位置计算、信号响应 |
| InputRegionManager | 统一收集可交互区域并调用DisplayServer穿透 |
| BattleWidget | 战斗场景、挂机信息、BagButton |
| 各Panel | 自身内容展示与交互 |

**禁止：** 面板直接控制全局窗口尺寸/穿透/拖动，面板互相new/delete/重排，面板自己计算全局布局。

---

## 7. 脚本职责表

| 脚本 | 职责 |
|---|---|
| window_shell.gd | 窗口创建、尺寸设置、透明标志、拖动转发 |
| dock_layout_controller.gd | 接收battle_widget_moved信号、计算面板位置 |
| input_region_manager.gd | 收集可交互区域Rect2列表、调用DisplayServer穿透 |
| battle_widget.gd | _gui_input处理拖动、发出battle_widget_moved信号、BagButton事件 |
| bag_panel.gd | toggle显示、发出打开/关闭信号 |
| 各panel脚本 | 自身内容更新、按钮事件 |

---

## 8. F5验收标准（10步）

1. 启动看到BattleWidget 720×180居中
2. 拖动BattleWidget流畅无闪烁
3. 点击BagButton打开BagPanel，宽度720
4. 打开HeroPanel显示在左侧
5. 打开SettingsPanel显示在右侧
6. 三栏同时打开时布局不重叠
7. 关闭BagPanel时所有Dock面板关闭
8. 透明区域鼠标穿透到桌面
9. BattleWidget始终不隐藏/不被PageHost切换
10. 窗口尺寸始终1440×720不变

---

## 9. 窗口系统冻结规范

以下数值/关系冻结，修改必须经过总控确认hash变更：

- 主窗口尺寸 1440×720
- BattleWidget尺寸 720×180
- 三栏锚点X坐标（16/360/1088）
- 窗口尺寸与三栏锚点的比例关系
- 冻结hash：0fd34a8

---

## 10. 透明窗口配置

Godot 4.7项目设置：
- display/window/size/viewport_width = 1440
- display/window/size/viewport_height = 720
- display/window/size/transparent = true
- display/window/per_pixel_transparency/enabled = true

---

## 11. InputRegionManager 设计

统一管理鼠标穿透区域。只收集：BattleWidget可交互矩形、BagPanel可见交互矩形、LeftDockHost/RightDockHost可见面板交互矩形、WindowDragLayer可拖动区域、当前打开弹窗的可交互控件。

不收集：隐藏页面、透明装饰、不可点击背景、纯视觉特效。

调用方式：DisplayServer.window_set_mouse_passthrough(regions)

---

## 附录：UI节点硬性铁则（10条）

> 以下规则整合自原Ui节点架构.txt，对所有UI开发具有最高约束力。

1. **三层节点封顶**：任意UI控件树深度不超过 Control → 容器 → 原子组件 三层
2. **独立tscn预制文件**：每个UI面板必须是独立.tscn文件，禁止代码new出面板结构
3. **全局Theme主题**：所有UI控件统一使用项目Theme资源（res://assets/ui/theme/roguefall_theme.tres），禁止面板各自定义StyleBox
4. **禁止多层嵌套**：Panel → Panel → Panel → ... 禁止，必须扁平化为 Panel → VBox/HBox → 原子控件
5. **自由拖拽位置**：BattleWidget默认居中但可拖拽，程序启动时居中放置
6. **MainRoot透明**：MainRoot自身透明，children控件不透明
7. **窗口透明**：通过Godot项目设置实现透明，禁止代码hack
8. **三层结构**：所有UI Panel必须使用 Background(Base) → Content(Vbox/Hbox) → Interaction(Button/Label) 三层结构
9. **面板固定关系**：BattleWidget常驻显示，其他面板toggle显示，面板之间通过信号通信
10. **禁止工具脚本污染**：临时Debug/HUD/控制台脚本禁止留在最终.tscn中
