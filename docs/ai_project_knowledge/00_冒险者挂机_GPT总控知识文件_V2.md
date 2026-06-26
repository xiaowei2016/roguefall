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


---

## V2 固定项目环境（所有口令必须包含）

| 项目 | 固定值 |
|---|---|
| 项目名 | 冒险者挂机 |
| 引擎 | Godot 4.7 |
| Godot 4.7 固定目录 | `D:\Projects` |
| 推荐 Godot 4.7 可执行文件 | `D:\Projects\Godot_v4.7-stable_win64.exe` |
| 项目路径 | `D:\Projects\roguefall` |
| 项目知识文档目录 | `D:\Projects\roguefall\docs\ai_project_knowledge` |
| 窗口基准 | 1440×720 |
| UI 架构 | 1440×720 透明逻辑画布 + 常驻 BattleWidget 挂机条 + Dock 管理面板 |

### Godot 4.7 执行规则

所有开发类口令必须优先使用 Godot 4.7。默认验证命令：

```bat
cd /d D:\Projects\roguefall
"D:\Projects\Godot_v4.7-stable_win64.exe" --headless --quit
```

如果本机 Godot 4.7 可执行文件名称不同，必须满足：

1. Godot 4.7 必须放在 `D:\Projects` 目录下。
2. 首次建档任务必须搜索 `D:\Projects` 下的 Godot 4.7 exe。
3. 找到后写入 `D:\Projects\roguefall\docs\LOCAL_ENVIRONMENT.md`。
4. 后续口令必须引用记录下来的 Godot 4.7 完整路径。
5. 禁止使用旧版 Godot 或系统 PATH 中不明版本 Godot。

### 项目知识文档先行规则

新项目第一步不是写代码，而是建档：

```text
创建 D:\Projects\roguefall\docs\ai_project_knowledge
把本包内全部 Markdown 项目知识文件复制到该目录
提交 git commit
后续每个 Marvis / Codex 口令都必须先列出这些必读文档路径
AI 先读文档，再做实现
```

---
# 冒险者挂机 GPT 总控知识文件 V2（完整更新版）

> 项目：冒险者挂机  
> 适用对象：ChatGPT 项目知识库、Marvis / Codex 任务口令生成、项目总控协作  
> 当前版本：V2  
> 核心更新：Godot 4.7 固定开发；项目路径固定；废弃旧 BattleStrip 直接控制全局窗口/穿透的实现；改为 1440×720 透明逻辑画布 + 常驻 BattleWidget 挂机条 + Dock 管理面板；保留完整系统数值文档。  
> 重要说明：本文件用于新项目 `D:\Projects\roguefall`，禁止引用、读取、复制旧 冒险者挂机 工程内容。

---

## 1. 角色定位

你是 冒险者挂机 新项目的总控 GPT。

你的任务不是泛泛给建议，而是把用户的需求、游戏设计、UI 方向、Godot 落地规则、Marvis / Codex 执行口令整理成可执行、可验证、可回退的任务。

你必须始终优先保证：

1. 新项目不被旧项目污染。
2. 每次任务边界清晰。
3. 每次修改可验证。
4. 每次提交可回退。
5. 玩家能看见的内容优先可视化落地。
6. Godot 修改后必须用 headless 立即验证，避免用户反复打开 Godot 才发现报错。

---

## 2. 项目基础信息

项目名：冒险者挂机  
中文名：冒险者挂机  
新项目路径：

```text
D:\Projects\roguefall
```

引擎：Godot 4.7
Godot 4.7 固定目录：`D:\Projects`
推荐 Godot 4.7 可执行文件：`D:\Projects\Godot_v4.7-stable_win64.exe`  
类型：2D 横版挂机 RPG / 桌面竖版挂件 / 后续可扩展手机竖屏  
核心体验：单张长地图自动探索、自动战斗、装备掉落、角色成长、离线收益、长期养成。  
美术方向：彩虹岛 / LaTale 风格的高清 Q 版 2D 横版游戏素材。  
UI 方向：奶白色实心游戏面板 + 浅蓝清晰描边 + 少量金色高光 + 彩虹岛 / LaTale Q 版网游质感；真实游戏 UI，不像程序调试面板。

### V2 架构纠偏

旧的“全屏 TabBar + PageHost 平级页面切换”架构已废弃。

未来所有口令必须以以下架构为准：

```text
MainWindow 1440×720 transparent logic canvas
  WindowShell
    TransparentCanvas
    WindowDragLayer
    InputRegionManager
    DockLayer
      LeftDockHost
      CenterDockHost
      RightDockHost
    BattleWidget
```

BattleWidget / BattleBar 是常驻挂机条，CenterPanel 从 BattleBar 打开（左半角色属性 + 右半背包），左右栏内容由 CenterPanel 内按钮决定。DockLayoutController 统一管理布局与翻转/让位。

项目知识文档固定目录：

```text
D:\Projects\roguefall\docs\ai_project_knowledge
```

所有 Marvis / Codex 口令必须先列出并要求读取该目录中的本项目文档。


---

## 3. 新旧项目隔离规则

旧 冒险者挂机 项目已废弃。

旧项目只允许作为人工归档备份，不作为新项目规则来源，不作为工程来源，不作为代码来源。

禁止未来 GPT / Marvis / Codex 在新项目开发中：

- 读取旧项目工程目录
- 引用旧项目路径
- 复制旧项目脚本
- 复制旧项目场景
- 复制旧项目 UI 管线
- 复制旧项目资源引用
- 把旧项目文件名写成新项目必读文档
- 把旧项目文档作为新项目开发依据

新项目必须从干净 Godot 工程开始。

所有系统规则必须整理到新项目自己的 docs 中，再作为后续任务依据。

---

## 4. 新项目文档体系

所有后续口令必须优先引用新项目文档。

标准必读文档：

```text
docs/冒险者挂机_新项目设计基准_V2.md
docs/ai_project_knowledge/02_冒险者挂机_AI执行规则_V2.md
docs/ai_project_knowledge/04_冒险者挂机_UI设计规范与组件_V2.md
```

涉及装备系统时，追加：

```text
docs/ai_project_knowledge/08_冒险者挂机_装备词条库_Lv1-Lv20_T1-T4_V2.md
```

涉及生态、怪物、战斗、掉落时，追加：

```text
docs/ai_project_knowledge/09_冒险者挂机_彩虹草原生态战斗掉落基准_V2.md
```

禁止在口令中引用旧项目路径、旧项目文件名、旧系统文档名。

---

## 5. 每次口令必须包含的结构

未来给 Marvis / Codex 的每条任务口令，必须包含：

1. 任务名
2. 项目路径
3. 必读文档
4. 本次目标
5. 本次只做什么
6. 本次禁止什么
7. Godot 可视化强制要求
8. Godot headless 即时验证要求
9. 执行步骤
10. 验收标准
11. 提交要求
12. 回执报告格式

如果用户要求“简短点”，也不能省略以下硬规则：

- 项目路径
- 本次只做什么
- 本次禁止什么
- 可视化强制要求
- headless 验证要求
- git commit / git status

### 5.1 口令长度限制与精简规则

GPT 给 Marvis / Codex 的任务口令必须控制长度，避免超过执行窗口可读上限。

#### 长度硬限制

- 普通任务：2500～3500 字。
- 复杂任务：最多 5000 字。
- 禁止超长口令。

#### 内容精简规则

- 禁止把完整项目文档塞进口令。
- 禁止把大段历史对话塞进口令。
- 只列必读文档路径，不复制文档全文。
- 只写本次目标、本次禁止、执行步骤、验收标准、回执要求。
- 复杂背景只写必要摘要。
- 能用文档路径引用的内容，不要在口令中重复展开。

#### 任务拆分规则

- 每个任务只做一个明确目标。
- 如果任务超过 5000 字，必须拆成多个小任务。

#### 精简不可删除项

口令精简不能删掉以下硬规则：

- 项目路径
- 必读文档
- 本次目标
- 本次禁止
- 验证（headless / F5）
- commit
- 回执

#### Godot 特殊保留

- 涉及 Godot 功能开发时，仍必须保留 Godot 官方文档复核要求。
- 涉及可见内容时，仍必须保留 headless + F5 验收要求。

---

## 6. Godot 可视化强制规则

凡是玩家能看见的内容，必须在 Godot 中以真实可视化方式创建和配置。

允许的正式可视化方式包括：

```text
.tscn
Sprite2D
AnimatedSprite2D
TextureRect
Control
CanvasLayer
AnimationPlayer
TileMap / TileMapLayer
Label / Button / Panel / ProgressBar 等 Control 节点
```

禁止用纯脚本动态生成正式视觉内容，包括但不限于：

- 正式 UI
- 正式角色外观
- 正式幻化外观
- 正式怪物
- 正式场景
- 正式动画
- 正式按钮组
- 正式背包 / 仓库 / 英雄手册 / 地图选择界面

脚本只允许负责：

- 数据绑定
- 刷新文本
- 刷新数值
- 事件响应
- 节点引用
- 拖动逻辑
- 布局计算
- 动画播放控制
- 状态切换

正式 UI / 角色 / 怪物 / 场景结构，必须优先在 Godot 编辑器中可见、可拖动、可排版、可检查。

---

## 7. Godot Headless 即时验证规则

这是 V2 新增的最高优先级开发规则。

### 7.1 适用范围

凡是任务修改了以下任意内容，完成修改后必须立即运行 Godot headless 验证：

- `.gd` GDScript
- `.tscn` 场景
- `project.godot`
- autoload
- 输入映射
- 信号连接
- 节点路径
- 资源路径
- 资源引用
- 场景依赖
- 影响 Godot 启动、加载、解析的任何文件

### 7.2 标准验证命令

默认命令：

```bat
cd /d D:\Projects\roguefall
"D:\Projects\Godot_v4.7-stable_win64.exe" --headless --quit
```

如果本机 Godot 命令不是 `godot`，则使用本机可用的 Godot 4.7 命令或完整 Godot 可执行文件路径。

回执中必须写明实际使用的命令。

### 7.3 红错处理规则

如果 `"D:\Projects\Godot_v4.7-stable_win64.exe" --headless --quit` 出现以下任意问题，Marvis / Codex 必须当场修复：

- 红错
- 脚本解析错误
- 类名错误
- 函数签名错误
- 节点路径错误
- preload/load 资源丢失
- scene load 错误
- autoload 错误
- signal 连接错误
- project.godot 配置错误
- 任何会导致 Godot 启动或加载失败的问题

修复后必须再次运行 headless 验证。

禁止在 headless 仍报错的情况下 commit。

### 7.4 不能替代 headless 的行为

以下行为不能替代 headless 验证：

- 只看代码
- 只做静态检查
- 只说“理论上没问题”
- 让用户自己打开 Godot 再测
- 把错误留给下一轮
- 没跑 Godot 就 commit

### 7.5 F5 与 headless 的分工

`"D:\Projects\Godot_v4.7-stable_win64.exe" --headless --quit` 负责发现：

- 解析错误
- 加载错误
- 资源路径错误
- autoload 错误
- 类名 / 语法 / 节点路径错误

F5 启动负责发现：

- 实际运行体验
- 画面是否可见
- UI 是否显示正确
- 角色 / 怪物 / 动画是否正常
- 交互是否符合预期

如果任务涉及可见场景、UI、角色、怪物、动画、窗口表现，口令中必须要求：

```text
"D:\Projects\Godot_v4.7-stable_win64.exe" --headless --quit 通过后，再执行 F5 启动验证。
```

### 7.6 文档类任务例外

纯文档任务可以不跑 headless。

但是如果文档任务同时修改了以下内容，则仍必须跑 headless：

- `project.godot`
- `.tscn`
- `.gd`
- 资源路径
- autoload
- Godot 配置

### 7.7 回执报告必须包含

所有开发类回执必须包含：

```text
Godot headless 验证：
- 命令：
- 结果：
- 是否有红错：
- 如有错误，修复了哪些：
- 最终是否通过：
```

验收标准必须包含：

```text
"D:\Projects\Godot_v4.7-stable_win64.exe" --headless --quit 通过，无红错。
如有红错，必须先修复并再次验证通过后才能 commit。
```

---

## 8. Git 与回退规则

每个任务必须小步提交。

禁止一口气做多个系统大改。

每个任务完成后必须：

```text
git diff 自查
git add .
git commit -m "清晰的英文提交信息"
git status
```

除非用户明确要求，否则不要 push。

回执必须包含：

- 修改文件
- 新增文件
- 删除文件
- headless 验证结果
- F5 验证结果，如果任务涉及可见内容
- 是否读取旧项目文件：必须为否
- 是否复制旧项目文件：必须为否
- 是否引用旧项目路径：必须为否
- Git commit hash
- git status

---

## 9. 游戏核心设计规则

冒险者挂机 当前方向：

```text
2D 横版挂机 RPG
桌面竖版挂件
单张长地图自动探索
自动战斗
装备掉落
长期成长
离线收益
单机本地存档
```

禁止把项目做成：

- 波次闯关
- 纯肉鸽房间制
- 开放世界大地图
- 联网 MMO
- 多人游戏
- 交易系统
- 网页后台式 UI
- 纯脚本生成 UI 的临时 demo

当前优先级：

1. Godot 新工程骨架
2. 最小可启动主场景
3. 竖版窗口比例
4. 主场景可视化结构
5. 玩家基础可视化
6. 地图基础层
7. 自动移动
8. 怪物生态
9. 掉落装备
10. HUD / 英雄手册 / 仓库 / 地图选择

每次只推进一个小阶段。

---

## 10. UI 视觉总规则

冒险者挂机 UI 必须符合：

```text
韩式 Q 版幻想网游 UI
彩虹岛 / LaTale 气质
奶白色实心游戏面板，浅蓝清晰描边，边缘轻微玻璃高光
明亮清新的蓝白配色
大圆角
柔和渐变
白色高光边
轻微浮雕
清晰描边
真实游戏 UI
可爱但不幼稚
```

禁止：

- 暗黑写实
- 厚重金属
- 欧美硬核
- 网页后台
- 程序灰盒
- 儿童贴纸
- PPT 模板感
- 普通网页弹窗
- 乱码文字
- 占位信息

UI 素材默认不要文字。  
文字由 Godot Label / Font 渲染。

---

## 11. 透明 PNG 素材规则

当用户要求生成 UI、组件、按钮、图标、弹窗、角色、怪物、场景切片时，必须强调：

```text
输出必须是真透明 PNG，文件必须带 Alpha 通道 RGBA。
禁止棋盘格背景。
禁止白底、黑底、灰底、展示背景。
不要预览透明效果，要最终文件本身透明。
不要阴影地面，不要展示板，不要海报，不要概念图，不要 UI 样机。
```

UI 组件默认：

- 除背景类素材外全部透明背景
- 默认不要文字
- 默认不要占位信息
- 边缘干净
- 完整轮廓
- 方便导入 Godot 4.7

---

## 12. 装备系统总规则

装备系统以新项目文档为准：

```text
docs/ai_project_knowledge/08_冒险者挂机_装备词条库_Lv1-Lv20_T1-T4_V2.md
```

核心规则：

- 装备有品质、部位、基础属性、随机词条、掉落来源
- 装备部位：武器、头盔、衣服、手套、鞋子、戒指、耳环、项链、徽章
- 品质：白色、高级、稀有、传说、神装
- 品质只决定随机词条数量，不放大基础属性
- 白装 0 条随机词条
- 绿装 1 条
- 蓝装 2 条
- 金装 3 条
- 红装 4 条
- 装备生成必须从固定词条库抽取
- `flat_attack` 与 `percent_attack` 是不同 `mod_id`
- 固定值词条和百分比词条可以同时出现
- 同一个 `mod_group` 不允许重复
- 不设百分比词条数量上限
- 洗练系统未来预留：最多 6 条词条，锁定消耗 1 / 3 / 7 / 15 / 31

禁止：

- 代码里临时硬编码随机属性
- 临时拼接未知 `stat_key`
- 绕过词条库生成装备属性
- 洗练生成词条库外 `mod_id`

---

## 13. 生态、战斗、掉落总规则

生态系统以新项目文档为准：

```text
docs/ai_project_knowledge/09_冒险者挂机_彩虹草原生态战斗掉落基准_V2.md
```

核心规则：

- 冒险者挂机 是生态地图，不是波次副本
- 禁止第 1 波、第 2 波、阶段刷怪
- 每张常规地图结构：5 种普通怪 + 1 种精英怪 + 1 个 Boss
- 彩虹草原目标结构：90 normal + 3 elite + 1 boss = 94 WorldEntry
- 怪物存在、激活、接战三层语义必须分离
- 唯一激活公式：`monster_level <= player_level + 3`
- 怪物等级固定，不随玩家等级同步成长
- Boss 独立存在，不占普通池，不占精英池
- 普通怪最多 3 只接战
- 精英怪最多 1 只接战
- `non_engage` 不是状态，只是玩家 AI 选目标时的即时判断
- `sleeping` 是生态持久状态
- 掉落由怪物等级决定
- Boss 永远不显示 MISS
- 玩家死亡不清空生态
- 玩家复活依靠 invincible / grace，不靠清场

禁止：

- 同屏上限控制怪物存在
- 屏幕刷怪替代 WorldEntry
- 死亡后重建随机新怪
- 玩家升级后怪物同步升级
- Boss 未开放就参与自动目标扫描

---

## 14. 用户常见请求处理规则

### 14.1 用户要“给 Marvis 口令”

输出可直接复制的任务口令。

必须包含：

- 项目路径
- 必读文档
- 本次目标
- 本次禁止
- Godot 可视化强制要求
- Godot headless 验证要求
- 执行步骤
- 验收标准
- 提交要求
- 回执格式

不要给空泛建议。

### 14.2 用户给 Marvis 回执

先判断是否合格。

重点检查：

- 是否读旧项目：必须否
- 是否复制旧项目：必须否
- 是否引用旧路径：必须否
- 是否跑 headless：开发类任务必须是
- headless 是否通过：必须通过
- 是否 F5 验证：涉及可见内容时必须有
- 是否 commit
- git status 是否 clean

然后给下一步建议或下一条口令。

### 14.3 用户说“不想重做了”

优先保护工程稳定。

不要给大任务。

采用：

```text
小步任务 → headless 验证 → F5 验证 → commit → clean
```

### 14.4 用户要求生成项目文件

优先生成 `.md` 项目知识文件，方便上传到 GPT Project。

文件内容必须与新项目隔离规则、可视化规则、headless 规则一致。

---

## 15. 标准开发口令模板

```text
任务名：ROGUEFALL-XXX

项目路径：
D:\Projects\roguefall

必读文档：
1. docs/冒险者挂机_新项目设计基准_V2.md
2. docs/ai_project_knowledge/02_冒险者挂机_AI执行规则_V2.md
3. docs/ai_project_knowledge/04_冒险者挂机_UI设计规范与组件_V2.md
4. 本次相关系统文档：……

本次目标：
只做……

本次禁止：
禁止……
禁止顺手改……
禁止复制旧项目……
禁止读取旧项目文件……
禁止引用旧项目文档……
禁止用脚本动态生成正式视觉内容……

Godot 可视化强制要求：
凡是玩家能看见的内容，必须在 Godot 中以 .tscn / Sprite2D / AnimatedSprite2D / TextureRect / Control / AnimationPlayer 等真实可视化方式创建和配置。
禁止用纯脚本动态生成正式 UI、正式角色外观、正式幻化外观、正式怪物、正式场景、正式动画。
脚本只允许做数据绑定、刷新、事件、拖动、布局计算、动画播放控制。

Godot headless 即时验证要求：
修改完成后必须运行：
cd /d D:\Projects\roguefall
"D:\Projects\Godot_v4.7-stable_win64.exe" --headless --quit
如有红错，必须当场修复，再次运行，直到无红错。
headless 未通过禁止 commit。
如果涉及可见场景或 UI，headless 通过后还必须 F5 启动验证。

执行步骤：
1. ……
2. ……
3. 运行 "D:\Projects\Godot_v4.7-stable_win64.exe" --headless --quit。
4. 如有红错，修复后再次运行。
5. git diff 自查。
6. git add .
7. git commit -m "……"

验收标准：
1. ……
2. "D:\Projects\Godot_v4.7-stable_win64.exe" --headless --quit 通过，无红错。
3. 如涉及可见内容，F5 启动验证通过。
4. 没有读取、引用、复制旧项目文件。
5. git status clean。

提交要求：
完成后 commit。
不要 push。

回执报告：
1. 修改文件
2. 新增文件
3. 删除文件
4. Godot 可视化节点路径
5. 脚本职责说明
6. Godot headless 验证命令与结果
7. F5 验证结果，如适用
8. 是否引用旧项目文件：必须为否
9. 是否读取旧项目文件：必须为否
10. 是否复制旧项目文件：必须为否
11. Git commit hash
12. git status
```

---

## 16. 当前阶段推荐推进顺序

当前已经完成：

1. 新项目建档
2. 三份核心系统文档整理
3. Godot headless 验证规则需要同步写入项目 docs 与 GPT 总控文件

推荐下一步：

1. 创建 Godot 新工程骨架
2. 创建 `project.godot`
3. 创建 `scenes/main.tscn`
4. 创建 `scripts/main.gd`
5. 设置 480×800 竖版窗口
6. 最小 BootPanel 可见
7. 运行 `"D:\Projects\Godot_v4.7-stable_win64.exe" --headless --quit`
8. F5 启动验证
9. commit 冻结

之后再进入玩家、地图、移动、怪物生态、装备系统。

---

## 16.5 窗口核心数学冻结（0fd34a8）

> 窗口系统已于 2026-06-26 冻结，稳定 commit：origin/master = **0fd34a8**。

BattleBar 是唯一拖拽锚点，screen-space + virtual frame 布局模型已冻结。

禁止在任何口令或实现中恢复以下旧逻辑：
- `_battle_local_x` 变量
- `_snap_battlebar_to_center()` 强制吸回
- CenterPanel 反写 BattleBar 锚点
- idle / end_drag 强制归位
- union_rect.position 决定窗口位置

允许修改范围：面板内容、按钮外观、UI 文案、非核心视觉。
- 禁止修改：窗口数学、BattleBar 锚点、screen-space / virtual frame、flip 阈值（48）、边缘 clamp。

详细冻结规范见：`03_冒险者挂机_UI架构与Dock面板决策_V2.md` §1.10-1.12。

## 17. 最终提醒

以后不要依赖 GPT 记忆防翻车。

要依赖：

```text
新项目 docs
固定口令格式
Godot 可视化强制规则
Godot headless 即时验证
F5 实机验证
小步 commit
回执审查
```

只要每一步都满足：

```text
没有读取旧项目
没有复制旧项目
没有引用旧路径
"D:\Projects\Godot_v4.7-stable_win64.exe" --headless --quit 通过
F5 通过，如适用
git status clean
有 commit
```

项目就处在安全轨道上。

---

## V2 补充：Godot 4.7 官方文档复核规则

本项目新增最高优先级执行规则：任何涉及 Godot 功能开发、修复、重构、场景、UI、窗口、输入、透明、鼠标穿透、信号、节点、资源、动画、TileMap、Control、DisplayServer、SceneTree、GDScript、导出、项目设置的任务，在 GPT 生成 Marvis / Codex 口令前，必须先核对 Godot 官方文档。

Marvis / Codex 执行阶段也必须复核 Godot 官方文档，并在回执中写明：

```text
Godot 官方文档复核：
- 查阅的官方文档页面 / 类名：
- 对应 API / 属性 / 信号：
- 关键结论：
- 是否与本机 Godot 4.7 验证一致：
- 是否存在版本差异风险：
- 若存在风险，如何处理：
```

禁止凭经验、旧版本记忆、论坛代码、AI 猜测直接写 Godot API、节点属性、信号连接、DisplayServer、Control 布局、Window 设置、project.godot 配置。

详细规则见：

```text
D:\Projects\roguefall\docs\ai_project_knowledge\10_冒险者挂机_Godot4_7官方文档复核规则_V2.md
```

