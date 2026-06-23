# 冒险者挂机 GPT 项目文件完整更新包 V2

本包用于重新开新项目并做隔离。

固定信息：

| 项目 | 值 |
|---|---|
| 项目名 | 冒险者挂机 |
| Godot 版本 | Godot 4.7 |
| Godot 4.7 固定目录 | `D:\Projects` |
| 推荐 Godot 4.7 exe | `D:\Projects\Godot_v4.7-stable_win64.exe` |
| 项目路径 | `D:\Projects\roguefall` |
| 项目文档目录 | `D:\Projects\roguefall\docs\ai_project_knowledge` |
| UI 架构 | 1440×720 透明逻辑画布 + 常驻 BattleWidget 挂机条 + Dock 管理面板 |

## 重要修正

V1.0 包不合格，已废弃。V2 做了以下修正：

1. 装备词条库完整保留原 Lv1-Lv20 / T1-T4 数值、权重、部位、洗练规则。
2. 生态战斗掉落文档完整保留 90 normal + 3 elite + 1 boss、怪物等级、怪物数值、掉率、药水、验收标准。
3. 项目名统一为“冒险者挂机”。
4. 项目路径固定为 `D:\Projects\roguefall`。
5. Godot 固定为 4.7，Godot 4.7 固定放在 `D:\Projects`。
6. 旧工程 BattleStrip 直接控制全局窗口/穿透的实现废弃。正式架构改为 WindowShell + 常驻 BattleWidget + DockLayer + DockLayoutController + InputRegionManager。
7. 新增首轮建档口令：必须先把整套文档放入 `D:\Projects\roguefall\docs\ai_project_knowledge`，后续 AI 先读文档再做实现。

## 使用方式

1. 解压本包。
2. 新建项目目录：`D:\Projects\roguefall`。
3. 创建：`D:\Projects\roguefall\docs\ai_project_knowledge`。
4. 把本包 Markdown 文件复制进去。
5. 将 `07_冒险者挂机_AI口令模板与初始化_V2.md` 里的首轮建档口令复制给 Marvis / Codex。

## 验证

本包生成时已做文本检查：

- 已完成项目名统一替换；正式项目名为“冒险者挂机”。
- `roguefall` 仅作为固定技术目录路径 `D:\Projects\roguefall` 使用。

---

## V2 官方文档复核规则补丁说明

本更新包在原 V1.1 基础上新增：

```text
10_冒险者挂机_Godot4_7官方文档复核规则_V2.md
```

并同步更新以下核心规则文件：

```text
00_冒险者挂机_GPT总控知识文件_V2.md
01_冒险者挂机_新项目设计基准_V2.md
02_冒险者挂机_AI执行规则_V2.md
03_冒险者挂机_UI架构与Dock面板决策_V2.md
07_冒险者挂机_AI口令模板与初始化_V2.md
```

使用方式：

1. 解压本包。
2. 将全部 Markdown 文件复制到：

```text
D:\Projects\roguefall\docs\ai_project_knowledge
```

3. 覆盖同名旧文档。
4. 后续所有 Godot 功能开发口令必须先查 Godot 官方文档，并要求 Marvis / Codex 在回执中写明官方文档复核结果。

