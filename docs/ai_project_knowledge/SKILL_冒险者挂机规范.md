---
AIGC:
    Label: "1"
    ContentProducer: 001191440300708461136T1XGW3
    ProduceID: a79647fa9a1466875b5116ce93417181_55eba2c7732611f1986d525400d9a7a1
    ReservedCode1: 3mHAYHaJk2iwa37Fra5gIfne3LOs0XzKiErWtfmjc0/zBQwTIOYT7mZlv9lecmtdKeQEB7qbO3Ia7s/lbozmIeH91WZF39eurhfbgB9rGcsPOAV/GWEO8b/JQiWo11vMXHXPpsEZ2GP1xHy4p6vRazlFGNdN2QOhVPA3cLuarDcbzyJGUqyB0jEMlVY=
    ContentPropagator: 001191440300708461136T1XGW3
    PropagateID: a79647fa9a1466875b5116ce93417181_55eba2c7732611f1986d525400d9a7a1
    ReservedCode2: 3mHAYHaJk2iwa37Fra5gIfne3LOs0XzKiErWtfmjc0/zBQwTIOYT7mZlv9lecmtdKeQEB7qbO3Ia7s/lbozmIeH91WZF39eurhfbgB9rGcsPOAV/GWEO8b/JQiWo11vMXHXPpsEZ2GP1xHy4p6vRazlFGNdN2QOhVPA3cLuarDcbzyJGUqyB0jEMlVY=
---



# 冒险者挂机 Godot 项目开发辅助

> Skill ID: `roguefall-dev`
> 引擎: Godot 4.7
> 项目根: D:\Projects\roguefall
> 文档目录: D:\Projects\roguefall\docs\ai_project_knowledge

---

## 零、项目环境

- **项目名称**: 冒险者挂机 (Roguefall)
- **引擎版本**: Godot 4.7
- **项目根目录**: `D:\Projects\roguefall`
- **知识库目录**: `D:\Projects\roguefall\docs\ai_project_knowledge`
- **主控场景**: `res://scenes/main.tscn`
- **主入口脚本**: `res://scripts/main.gd`

---

## 一、文档体系（9文件，只读基线）

| # | 文件名 | 用途 |
|---|--------|------|
| 00 | 总控_V3 | 项目全貌、文档体系、设计方向、禁止列表 |
| 01 | 设计基准_V3 | 游戏定位、数值框架、目录结构、美术方向 |
| 02 | AI执行规则_V3 | 核心开发规则硬约束，含数据架构§10 |
| 03 | UI架构与Dock面板决策_V3 | 翻转/让位/穿透机制、节点树、尺寸常量 |
| 04 | UI设计规范与开发_V3 | 视觉风格、组件体系、生图prompt、页面规格 |
| 05 | 辅助系统_装备幻化图鉴宠物_V3 | 装备幻化、图鉴、宠物 |
| 06 | AI口令模板与初始化_V3 | GPT口令格式、200-300字硬限制 |
| 07 | 装备词条库_V3 | 16个mod_id、T1-T4数值、部位词条池 |
| 08 | 彩虹草原生态战斗掉落_V3 | 7种生物、94 WorldEntry、掉率表 |
| 09 | Godot文档复核规则_V3 | 文档自检规则 |

---

## 二、核心约束速查

### 2.1 数据架构硬约束

- **两层架构**: CSV 外置数据表 + DataManager 全局单例（砍 TRES）
- **五大固定数据库**: 怪物 / 掉落权重 / 装备基础 / 词条数值 / 图鉴与宠物
- **目录规范**: `res/data_csv/` + `res/scripts/data_core/`
- **强制规则**: 禁止文字匹配、禁止硬编码数值、禁止嵌套结构、修改数值只改 CSV

### 2.2 UI架构约束

- **翻转**: BattleBar 拖拽时按上下空间+48px滞后自动判定（FLIP_HYSTERESIS=48）
- **让位**: 面板组溢出屏幕边缘时整体平移
- **穿透**: Win32像素穿透活跃（DesktopPixelPassthrough.cs），Godot层已废除
- **面板**: WarehouseContent / PetContent / BattleBar / CenterPanel
- **窗口**: 1440x718 透明画布

### 2.3 美术与生图

- AI生图必须纯品红 #FF00FF 背景
- 禁止伪透明/棋盘格/格子背景
- 品红背景由美术后期一键去底

### 2.4 GPT口令

- 200-300字严格上限
- 必读文档默认1份，跨系统最多3份

### 2.5 装备系统

- 装备幻化：整套非逐部位，幻化与属性零耦合
- 词条：16个mod_id、T1-T4数值、部位词条池

---

## 三、执行流程

```
收到开发任务
  -> Step 1: 判断涉及范围，读取对应编号文档
  -> Step 2: 对齐 §二 核心约束速查
  -> Step 3: 严格按 GPT 口令 + 文档规范执行写代码
  -> Step 4: 用户验收
```

---

## 四、硬边界

- 禁止引用旧项目（roguefall_old 仅人工归档）
- 禁止使用已废弃架构名（WindowShell / DockLayoutController / InputRegionManager）
- 禁止推翻数据架构
- 禁止嵌套数据结构、禁止冗余表
- 修改数值只改 CSV，禁止改代码
*（内容由AI生成，仅供参考）*
