<!--
冒险者挂机 GPT 项目知识文件 V2 官方文档复核规则补充版
固定信息：
- 项目名：冒险者挂机
- 引擎版本：Godot 4.7
- Godot 4.7 固定目录：D:\Projects
- 推荐 Godot 4.7 可执行文件：D:\Projects\Godot_v4.7-stable_win64.exe
- 项目固定路径：D:\Projects\roguefall
- 项目知识文档固定目录：D:\Projects\roguefall\docs\ai_project_knowledge
- UI 架构：1440×720 透明逻辑画布 + 常驻 BattleWidget 挂机条 + Dock 管理面板
- 旧实现废弃：旧 BattleStrip / layout_shell 直接控制全局窗口、穿透、拖动和三栏绑定；新架构由 WindowShell、DockLayoutController、InputRegionManager 统一管理
- 新增最高规则：任何 Godot 功能开发前必须复核 Godot 官方文档
-->

# 冒险者挂机 Godot 4.7 官方文档复核规则 V2

## 1. 最高规则

任何涉及 Godot 功能开发、修复、重构、场景、UI、窗口、输入、透明、鼠标穿透、信号、节点、资源、动画、TileMap、Control、DisplayServer、SceneTree、GDScript、导出、项目设置的任务，GPT 在生成 Marvis / Codex 口令前，必须先查 Godot 官方文档。

Marvis / Codex 执行任务时，也必须复核 Godot 官方文档。

禁止凭经验、旧版本记忆、其他项目代码、论坛片段、AI 猜测直接写实现。

## 2. 官方文档优先级

优先级如下：

1. Godot 官方文档：`https://docs.godotengine.org`
2. Godot 官方类文档 / Class reference，例如 `DisplayServer`、`Control`、`Node`、`SceneTree`、`Window`、`InputEvent`、`Tween`、`AnimationPlayer`、`Button`、`Panel`、`ColorRect`。
3. Godot 官方教程 / Tutorials，例如 UI、2D、Animation、Input、Command line、Export、Project settings。
4. Godot 本机编辑器内置文档 / Class reference。
5. Godot 可执行文件命令行帮助，例如：

```bat
D:\Projects\Godot_v4.7-stable_win64.exe --help
```

非官方论坛、博客、视频、AI 回答只能作为补充参考，不能作为第一依据。

## 3. 版本规则

项目固定使用 Godot 4.7：

```text
D:\Projects\Godot_v4.7-stable_win64.exe
```

每次涉及 Godot 技术实现时，必须优先核对 Godot 4.7 对应官方文档。

如果官方在线文档没有 exact 4.7 页面，必须：

1. 记录实际查阅的官方文档版本，例如 stable / latest / 4.x / 4.6 / 4.5。
2. 明确写出与 Godot 4.7 的潜在差异风险。
3. 用本机 Godot 4.7 headless、F5、编辑器内置文档复核。
4. 不允许把旧版本 API 当作 4.7 API 直接使用。
5. 如果 API、属性、节点行为不确定，必须暂停并回报，不允许盲改。

## 4. GPT 口令生成要求

以后 GPT 给 Marvis / Codex 的每条功能开发口令，必须增加一节：

```text
Godot 官方文档复核要求
```

该节必须写明：

1. 本任务涉及哪些 Godot 技术点。
2. 必须查哪些官方文档主题、类名或关键词。
3. 禁止使用哪些猜测性写法。
4. 如果官方文档与本机 Godot 4.7 行为不一致，必须暂停回报。
5. 回执必须列出已查阅的官方文档主题、API 名称、关键结论。

示例：

```text
本任务涉及 Control 布局、Button 信号、Panel / ColorRect 可视化节点。
执行前必须查阅 Godot 官方文档：
- Control
- Button
- BaseButton.pressed
- Panel
- ColorRect
- Node.visible / CanvasItem.visible
不得凭旧版本经验猜测属性名、信号名或锚点行为。
```

## 5. Marvis / Codex 执行要求

Marvis / Codex 每次功能开发回执必须增加：

```text
Godot 官方文档复核：
- 查阅的官方文档页面 / 类名：
- 对应 API / 属性 / 信号：
- 关键结论：
- 是否与本机 Godot 4.7 验证一致：
- 是否存在版本差异风险：
- 若存在风险，如何处理：
```

如果回执没有这一节，本次任务不得冻结。

## 6. 特殊高风险技术

以下任务必须特别查官方文档：

1. DisplayServer / 透明窗口 / 鼠标穿透。
2. Control 布局、锚点、offset、size、theme、focus、mouse_filter。
3. Button / BaseButton / pressed / toggle_mode / button_pressed。
4. Window / viewport / project.godot display 设置。
5. AnimationPlayer / AnimatedSprite2D / SpriteFrames。
6. TileMap / TileMapLayer。
7. FileAccess / ResourceLoader / ResourceSaver / save/load。
8. Autoload / singleton。
9. SceneTree / PackedScene / instantiate。
10. InputEvent / mouse drag / global/local coordinates。
11. Export / Windows 平台设置。
12. Headless / command line 参数。
13. CanvasLayer / Control 层级 / UI 输入穿透。
14. Signal 连接方式、Callable、typed signals。

## 7. Headless 与 F5 分工

headless 只能证明项目能加载、脚本能解析、资源路径大体正确。

窗口位置、透明、鼠标穿透、UI 可见性、按钮点击、拖动、动画表现，必须 F5 可视化验证。

规则：

1. headless 通过不能替代 F5。
2. 涉及窗口、UI、动画、角色、怪物、场景的任务，必须 F5 验证。
3. Marvis / Codex 不得用“headless 通过”宣布画面验收完成。
4. F5 画面验收由用户或用户截图回传 GPT 判定。
5. 如果 headless 与 F5 结果不一致，以 F5 现象为准继续排查。

## 8. 禁止事项

禁止：

1. “应该是这样”的 Godot API 猜测。
2. 使用旧 Godot 3.x 写法。
3. 使用 Godot 4.5 / 4.6 文档结论却不说明版本差异。
4. 使用论坛代码直接粘贴。
5. 不查官方文档就写 DisplayServer。
6. 不查官方文档就改 Control 锚点和布局。
7. 不查官方文档就改信号连接。
8. 不查官方文档就修改 `project.godot`。
9. 不查官方文档就声明功能完成。
10. 官方文档不确定时继续盲修。
11. 用 AI 记忆替代官方文档。
12. 用“能跑”替代“符合官方 API 与项目规则”。

## 9. 冻结标准

任何功能开发任务，只有同时满足以下条件才允许冻结：

1. 项目必读文档已读。
2. Godot 官方文档已查。
3. 官方文档结论已写入回执。
4. Godot 4.7 headless 通过。
5. 涉及可见内容时 F5 验收通过。
6. `git status` clean。
7. 没有版本差异风险，或风险已说明并由用户确认。

## 10. 口令固定段模板

以后所有功能开发口令必须包含：

```text
Godot 官方文档复核要求：
本任务涉及 Godot 技术点：{列出 Control / Button / DisplayServer / SceneTree / InputEvent 等}
执行前必须查阅 Godot 官方文档或本机 Godot 4.7 内置类文档：
- {官方类名或主题 1}
- {官方类名或主题 2}
- {官方类名或主题 3}
禁止凭经验猜 API、属性、信号、节点行为。
如果官方文档与本机 Godot 4.7 行为不一致，必须暂停并回报。
回执必须列出查阅的官方文档、关键 API、结论和版本差异风险。
```
