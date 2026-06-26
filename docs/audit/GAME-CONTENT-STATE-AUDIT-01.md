---
AIGC:
    Label: "1"
    ContentProducer: 001191440300708461136T1XGW3
    ProduceID: a79647fa9a1466875b5116ce93417181_145f677f710411f1986d525400d9a7a1
    ReservedCode1: bsOXmhhVO4iZw0wD7cX2YtcFqVg49+aQBJhL5OUjJPns85OoO8U037zz4aTVOU7JMERnq99zUq3Ba8V+GPJb0OKkrZ2BdzBEJu2lLYIqQX469a6lJ2Rq6TN9APVGKmgCYi+blFlvHrUou3y9D4tzjyti0zAjBoaG5Eoo/4mbKCnoQHyCfQ469sEWE9M=
    ContentPropagator: 001191440300708461136T1XGW3
    PropagateID: a79647fa9a1466875b5116ce93417181_145f677f710411f1986d525400d9a7a1
    ReservedCode2: bsOXmhhVO4iZw0wD7cX2YtcFqVg49+aQBJhL5OUjJPns85OoO8U037zz4aTVOU7JMERnq99zUq3Ba8V+GPJb0OKkrZ2BdzBEJu2lLYIqQX469a6lJ2Rq6TN9APVGKmgCYi+blFlvHrUou3y9D4tzjyti0zAjBoaG5Eoo/4mbKCnoQHyCfQ469sEWE9M=
---

# GAME-CONTENT-STATE-AUDIT-01

> 审计日期：2026-06-26  
> 审计类型：只读  
> 项目路径：`D:\Projects\roguefall`  
> 代码稳定点：`0fd34a8`  
> 文档同步点：`3185c21`  

---

## 1. 当前可玩的完整流程

**结论：无。**

当前项目**没有可玩内容**。启动 Godot 后仅显示一个透明无边框窗口，内含：

- 一个底部横条区域（BattleBar），其中放置一个 **"背包"** 按钮
- 点击"背包"后展开一个**完全空白**的中间面板，面板内有 **"左栏"** 和 **"右栏"** 两个按钮
- 点击"左栏"/"右栏"分别展开另外两个**完全空白**的侧面板

存在以下「流程」仅属于窗口 UI 框架的可见/隐藏切换，**不含任何游戏逻辑**：

| 操作 | 效果 | 真实度 |
|---|---|---|
| 点击"背包" | 显示/隐藏空白 CenterPanel | 纯窗口切换 |
| 点击"左栏" | 显示/隐藏空白 LeftPanel | 纯窗口切换 |
| 点击"右栏" | 显示/隐藏空白 RightPanel | 纯窗口切换 |
| 拖动 Panels | 拖拽窗口位置 | 窗口管理功能，非游戏逻辑 |

所有设计文档（01~10）中描述的游戏系统（战斗、怪物、掉落、装备、背包、角色、宠物、存档等）**均未实现任何一行代码**。

---

## 2. 当前真实完成的系统

### 2.1 窗口框架系统 — 已完成 ✅

**文件**：`scripts/main.gd`（326行） + `scripts/native_drag_zone.gd`（11行） + `scenes/main.tscn`（127行）

| 功能 | 状态 | 说明 |
|---|---|---|
| 透明无边框窗口 | ✅ 完成 | `project.godot` borderless+transparent + 每帧 `win.transparent = true` |
| 窗口尺寸 1440×720 | ✅ 完成 | 硬编码常量 `WIN_W`/`WIN_H` |
| 5 模式面板系统 | ✅ 完成 | `BATTLE_ONLY` / `CENTER_BATTLE` / `LEFT_CENTER_BATTLE` / `CENTER_RIGHT_BATTLE` / `FULL` |
| Screen-space 无状态布局 | ✅ 完成 | `_do_layout()` 完全基于 BattleBar 屏幕锚点计算，不依赖上一次 local position |
| BattleBar 唯一锚点 | ✅ 完成 | `_battle_anchor_screen_x/y` 作为唯一拖拽真源 |
| 拖拽移动窗口 | ✅ 完成 | `native_drag_zone.gd` → `main.start_drag()`/`end_drag()` → `_process()` 每帧重算布局 |
| 上下翻转逻辑 | ✅ 完成 | 带 48px 滞后的翻转判断，面板自动出现在 BattleBar 上方或下方 |
| 面板组屏幕边缘 clamp | ✅ 完成 | 面板组超出屏幕时自动 `panel_shift`，不影响 BattleBar 位置 |
| 窗口位置持久化 | ✅ 完成 | `_save_position()`/`_load_position()` 写入 `user://window.cfg` |
| 布局日志系统 | ✅ 完成 | 节流日志输出，区分 mode/flip/shift/idle/throttle 原因 |
| 首次居中 | ✅ 完成 | `_center_on_screen()` 兜底 |

#### 当前场景结构（从 `main.tscn` 实际解析）

```
MainRoot (Control, 1440×720)
├── PanelRoot (Control, full_rect)
│   ├── LeftPanel (Control, 352×530)
│   │   └── Panel (带 drag_zone 脚本) — 空容器
│   ├── CenterPanel (Control, 720×530)
│   │   ├── Panel (带 drag_zone 脚本)
│   │   ├── Button "左栏"
│   │   └── Button "右栏"
│   ├── RightPanel (Control, 352×530)
│   │   └── Panel (带 drag_zone 脚本) — 空容器
│   └── BattleBar (Control, 720×180)
│       ├── Panel (带 drag_zone 脚本)
│       └── Button "背包"
```

#### 按钮连接（唯一存在的交互）

| 按钮 | 信号 | 回调 | 行为 |
|---|---|---|---|
| BattleBar/Button "背包" | `pressed` | `_on_bag()` | 切换 `BATTLE_ONLY` ↔ `CENTER_BATTLE` |
| CenterPanel/Button "左栏" | `pressed` | `_on_left()` | 切换左栏显示/隐藏 |
| CenterPanel/Button2 "右栏" | `pressed` | `_on_right()` | 切换右栏显示/隐藏 |

#### 穿透逻辑

```gdscript
func _update_passthrough() -> void:
    pass  # 穿透暂时废除，等 BattleBar / 三栏布局稳定后再接入
```

穿透已被注释掉，整个窗口区域目前为**完全不穿透**。

---

### 2.2 设计文档体系 — 已完成 ✅

`docs/ai_project_knowledge/` 下 11 份 Markdown 文档已完整到位：

| 编号 | 文档 | 大小 |
|---|---|---|
| 00 | GPT总控知识文件 | 23KB |
| 01 | 新项目设计基准 | 38KB |
| 02 | AI执行规则 | 9.7KB |
| 03 | UI架构与Dock面板决策 | 12KB |
| 04 | UI设计规范与组件 | 6.6KB |
| 05 | UI开发与页面生成 | 9.4KB |
| 06 | 辅助系统（时装/图鉴/宠物） | 4.8KB |
| 07 | AI口令模板与初始化 | 10KB |
| 08 | 装备词条库 Lv1-Lv20 T1-T4 | 18KB |
| 09 | 彩虹草原生态战斗掉落基准 | 33KB |
| 10 | Godot 4.7 官方文档复核规则 | 7KB |

---

### 2.3 项目配置 — ✅ 完成

`project.godot` 配置：
- 项目名：Roguefall
- 主场景：`res://scenes/main.tscn`
- 窗口：1440×720，borderless + transparent + per_pixel_transparency
- 渲染：forward_plus + transparent_background

---

## 3. 假按钮 / 占位页面清单

### 3.1 按钮 = 空面板开关（无任何游戏逻辑）

| 按钮文本 | 所在位置 | 实际行为 | 预期行为（设计文档） | 分类 |
|---|---|---|---|---|
| **"背包"** | BattleBar | 仅显示/隐藏空白 CenterPanel | 打开背包界面，显示物品列表、装备栏 | 🔴 假按钮 |
| **"左栏"** | CenterPanel | 仅显示/隐藏空白 LeftPanel | 仓库/英雄面板切换 | 🔴 假按钮 |
| **"右栏"** | CenterPanel | 仅显示/隐藏空白 RightPanel | 地图/设置面板切换 | 🔴 假按钮 |

### 3.2 面板 = 完全空容器

| 面板 | 设计文档规划内容 | 实际内容 | 子节点数 |
|---|---|---|---|
| LeftPanel | WarehousePanel / HeroPanel | 仅一个带 drag_zone 的 Panel，无任何 UI 子节点 | 1 |
| CenterPanel | BagPanel（背包界面） | Panel + 2 个按钮，无任何 UI 子节点 | 3 |
| RightPanel | MapPanel / SettingsPanel | 仅一个带 drag_zone 的 Panel，无任何 UI 子节点 | 1 |
| BattleBar | HP/Exp/Gold/状态 | Panel + 1 个按钮，无任何状态显示组件 | 2 |

### 3.3 设计文档中提及但完全未创建的节点

以下为设计文档 03 中规划的架构，**无一实现**：

```
规划但未创建：
├── WindowShell          — 未创建
├── TransparentCanvas    — 未创建
├── WindowDragLayer      — 未创建
├── InputRegionManager   — 未创建
├── DockLayer            — 未创建
├── DockHost (Left/Center/Right) — 未创建
├── WarehousePanel       — 未创建
├── HeroPanel            — 未创建
├── BagPanel             — 未创建（仅一个按钮占位）
├── MapPanel             — 未创建
├── SettingsPanel        — 未创建
├── TitleLabel           — 未创建
├── HpBar                — 未创建
├── ExpBar               — 未创建
└── GoldLabel            — 未创建
```

---

## 4. 明显 Bug 清单

### 4.1 功能性 Bug

| # | 描述 | 严重度 | 位置 |
|---|---|---|---|
| 1 | `_update_passthrough()` 为空函数，穿透逻辑已废除但未移除调用 | 🟡 低 | `main.gd:191` |
| 2 | 没有任何 autoload 单例注册，未来添加全局数据系统时需修改 `project.godot` | 🟢 信息 | `project.godot` |
| 3 | `Mode` enum 定义了 5 种模式，但 `_on_left()`/`_on_right()` 的状态机从中间模式起步，从 `BATTLE_ONLY` 点击"背包"后才进入 `CENTER_BATTLE`，之后左右按钮才有意义——交互发现性差 | 🟡 低 | `main.gd:284-297` |

### 4.2 设计文档与实际代码不一致

| # | 描述 | 严重度 |
|---|---|---|
| 1 | 文档规划 `WindowShell` + `DockLayoutController` + `InputRegionManager` 三层架构，实际仅一个 `MainRoot` Control 加 `native_drag_zone` | 🔴 关键不一致 |
| 2 | 文档规划 `ContentContainer` 包裹 `WindowShell`/`TransparentCanvas`/`DockLayer` 等，实际场景只有 `PanelRoot` 直接放置四个面板 | 🔴 关键不一致 |
| 3 | 文档规划 `BattleWidget` 内含 `HpBar`/`ExpBar`/`GoldLabel`，实际 `BattleBar` 只有一个"背包"按钮 | 🔴 关键不一致 |
| 4 | 文档提到 `DockHost` 面板切换逻辑，实际无任何 Dock 系统 | 🔴 关键不一致 |

---

## 5. 未实现系统全量清单（对照审计目标）

### 主流程

| 流程环节 | 状态 | 说明 |
|---|---|---|
| 启动游戏 | ⚠️ 仅窗口启动 | 无标题画面、无加载界面 |
| 战斗系统 | ❌ 未实现 | 无任何战斗逻辑 |
| 怪物刷新 | ❌ 未实现 | 无怪物、无刷新 |
| 自动攻击 | ❌ 未实现 | 无攻击逻辑 |
| 掉落系统 | ❌ 未实现 | 无掉落 |
| 拾取系统 | ❌ 未实现 | 无拾取 |
| 背包系统 | ❌ 未实现 | 仅一个按钮占位 |
| 装备系统 | ❌ 未实现 | 无装备 |
| 属性变化 | ❌ 未实现 | 无属性 |
| 存档/读档 | ❌ 未实现 | 仅窗口位置持久化（非游戏存档） |

### UI 页面

| 页面 | 状态 |
|---|---|
| 主城 | ❌ 未实现 |
| 背包 | 🔴 假按钮 |
| 装备 | ❌ 未实现 |
| 角色 | ❌ 未实现 |
| 宠物 | ❌ 未实现 |
| 管理面板 | ❌ 未实现 |
| 底部按钮 | ⚠️ 仅"背包"按钮 |
| 顶部状态栏 | ❌ 未实现 |

### 数据系统

| 系统 | 状态 |
|---|---|
| 金币 | ❌ 未实现 |
| 经验 | ❌ 未实现 |
| 等级 | ❌ 未实现 |
| HP | ❌ 未实现 |
| 装备属性 | ❌ 未实现 |
| 掉落表 | ❌ 未实现 |
| 存档字段 | ❌ 未实现 |

---

## 6. 下一阶段最应该做的 3 个任务

按优先级排序：

### 任务 1：完成 BattleBar 常驻挂机条 UI（HP / Exp / 金币 / 等级）

**理由**：BattleBar 是唯一始终可见的区域，也是玩家与游戏交互的第一触点。当前只有一个"背包"按钮，无法传达任何游戏状态。

**范围**：
- 在 BattleBar 上添加 HP 条、Exp 条、金币 Label、等级 Label
- 创建 `GameData` autoload 单例，管理这些基础属性
- 信号驱动更新 UI（HP 变化 → HP 条刷新）

**预估工作量**：小（1 个 autoload + 修改 main.tscn + 1 个新脚本）

---

### 任务 2：搭建 Dock 面板架构 + 实现背包面板

**理由**：BattleBar 的"背包"按钮是目前唯一的用户入口，但它只切换一个空面板。需要让背包按钮真正打开一个有内容的背包面板，并建立 Dock 面板的宿主架构。

**范围**：
- 创建 `DockHost` 管理面板切换
- 创建 `BagPanel` 场景（物品列表 + 装备槽）
- 创建 `ItemData` 资源类
- 背包按钮打开/关闭 BagPanel 并正确控制穿透

**预估工作量**：中（2-3 个新场景 + 2-3 个新脚本 + autoload 扩展）

---

### 任务 3：实现最小可玩战斗循环（自动攻击 → 掉落 → 拾取）

**理由**：战斗是挂机游戏的核心，但前提是先有 BattleBar 状态显示和背包面板接收掉落物，因此排在任务 1、2 之后。

**范围**：
- 创建 `BattleManager` autoload（战斗逻辑）
- 实现自动攻击倒计时 + 伤害结算
- 实现简单掉落表（金币 + 装备）
- 掉落物自动进入背包
- BattleBar 实时反映 HP/Exp/金币变化

**预估工作量**：大（3-4 个新脚本 + autoload + 数据表）

---

## 7. 推荐第一个实施任务

**任务 1：完成 BattleBar 常驻挂机条 UI**

这是所有后续开发的前提。理由：
1. BattleBar 是用户始终可见的窗口，无状态显示 = 无"游戏感"
2. 实现 BattleBar UI 时会自然创建 `GameData` autoload，这是后续所有系统的数据基础
3. `GameData` 中的 HP/Exp/金币/等级字段后续可被战斗、背包、存档等系统直接复用
4. 改动范围极小（1 个 autoload + 修改现有场景），风险低
5. 不涉及窗口核心数学（不碰 `main.gd` 的 `_do_layout` 等冻结逻辑）

---

## 8. 涉及文件清单

### 当前实际存在的文件

| 文件 | 类型 | 行数 | 说明 |
|---|---|---|---|
| `project.godot` | 配置 | 31 | 项目配置 |
| `scenes/main.tscn` | 场景 | 127 | 主场景（唯一场景） |
| `scripts/main.gd` | 脚本 | 326 | 窗口管理核心（已冻结） |
| `scripts/native_drag_zone.gd` | 脚本 | 11 | 拖拽事件代理 |
| `scripts/main.gd.uid` | 元数据 | 1 | UID 文件 |
| `scripts/native_drag_zone.gd.uid` | 元数据 | 1 | UID 文件 |
| `.gitignore` | 配置 | 1 | Git 忽略规则 |
| `docs/LOCAL_ENVIRONMENT.md` | 文档 | - | 本地环境配置 |
| `docs/ai_project_knowledge/00~10_*.md` | 设计文档 | 11 份 | 项目设计文档体系 |
| `docs/ai_project_knowledge/README_*.md` | 文档 | 1 份 | 文档使用说明 |

### 设计文档规划但尚未创建的文件

| 规划文件 | 对应设计文档章节 | 优先级 |
|---|---|---|
| `scripts/autoload/game_data.gd` | 01 §系统边界 | P0 |
| `scenes/battle_bar.tscn` | 03 §1.4 BattleWidget | P0 |
| `scenes/bag_panel.tscn` | 03 §1.3 BagPanel | P1 |
| `scenes/warehouse_panel.tscn` | 03 §1.3 WarehousePanel | P2 |
| `scenes/hero_panel.tscn` | 03 §1.3 HeroPanel | P2 |
| `scenes/map_panel.tscn` | 03 §1.3 MapPanel | P3 |
| `scenes/settings_panel.tscn` | 03 §1.3 SettingsPanel | P3 |
| `scripts/dock/dock_host.gd` | 03 §1.1 DockLayer | P1 |
| `scripts/battle/battle_manager.gd` | 01 §系统边界 | P1 |
| `scripts/data/item_data.gd` | 08 §装备词条库 | P1 |
| `scripts/data/drop_table.gd` | 09 §掉落基准 | P2 |
| `scripts/data/equipment_affix.gd` | 08 §装备词条库 | P2 |

---

## 附录：项目进度总览图

```
冒险者挂机 (roguefall) 项目进度
═══════════════════════════════════════════════════════════════

████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  ~3%

已完成:
  ██ 窗口框架系统 (100%)
      透明无边框窗口、拖拽、面板切换、位置持久化、翻转逻辑
  ██ 设计文档体系 (100%)
      11 份知识文档全部到位
  ██ 项目配置 (100%)

未开始:
  ░░ BattleBar UI (0%)     — HP/Exp/金币/等级/状态
  ░░ Dock 面板架构 (0%)    — 面板宿主/切换/穿透管理
  ░░ 背包系统 (0%)         — 物品列表/装备槽/交互
  ░░ 战斗系统 (0%)         — 自动攻击/怪物/伤害结算
  ░░ 掉落系统 (0%)         — 掉落表/掉落物/自动拾取
  ░░ 装备系统 (0%)         — 词条/品质/部位/强化/洗练
  ░░ 角色系统 (0%)         — 属性/技能/升级
  ░░ 宠物系统 (0%)         — 宠物/出战/属性
  ░░ 存档系统 (0%)         — 完整存档/读档
  ░░ 主城系统 (0%)         — 地图/关卡选择
  ░░ 管理面板 (0%)         — 设置/地图/图鉴/时装
  ░░ 纸娃娃系统 (0%)       — 装备外观
  ░░ 穿透管理 (0%)         — InputRegionManager (已注释)
  ░░ 音效系统 (0%)
  ░░ 动画系统 (0%)
```

---

*审计完成时间：2026-06-26*

*审计范围：`scripts/*.gd`（2 个有效脚本） + `scenes/*.tscn`（1 个场景） + `project.godot` + `docs/ai_project_knowledge/*.md`（11 份设计文档）*
*（内容由AI生成，仅供参考）*
