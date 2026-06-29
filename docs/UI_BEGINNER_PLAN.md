# Roguefall UI 制作计划和调整指南

## 当前思路

项目采用 Godot 4 原生节点搭 UI。你主要在 Godot 编辑器里调整 `.tscn` 场景，不需要先写复杂代码。

窗口是透明桌面悬浮窗，核心布局分为四块：

1. `BattleBar`：底部 720 x 180 战斗条，常驻显示。
2. `CenterPanel`：中间 720 x 530 主面板，点击“背包”打开。
3. `LeftPanel`：左侧 352 x 530 功能面板，显示仓库、宠物、图鉴、地图。
4. `RightPanel`：右侧 352 x 530 功能面板，显示设置、洗练、详情。

## 主要文件

- `scenes/main.tscn`：总界面，负责窗口、三栏布局、按钮、左右功能页。
- `ui/root/center_main_panel.tscn`：中心角色/装备/背包面板。
- `scenes/GrasslandStage2D.tscn`：底部战斗条里的草原预览。
- `scripts/main.gd`：按钮切换、窗口位置、基础数据刷新。
- `scripts/DesktopPixelPassthrough.cs`：像素级穿透，不要随意删除。
- `assets/ui/icons/`：底部和面板标题图标。
- `assets/ui/_incoming/center_panel_back.png`：中心面板背景。

## 在 Godot 里怎么改

### 改中心角色面板

打开：

`ui/root/center_main_panel.tscn`

常改节点：

- `TitleLabel`：标题文字。
- `HeroCard`：左侧人物、装备、属性区域。
- `HeroIcon`：人物图标或以后替换成角色立绘。
- `SlotLeft1` 到 `SlotLeft3`：人物左边 3 件装备。
- `SlotRight1` 到 `SlotRight3`：人物右边 3 件装备。
- `SlotBottom1` 到 `SlotBottom3`：人物底部 3 件装备。
- `StatList`：人物属性区。
- `BagPanel/BagGrid`：右侧背包格子，当前是 5 列 x 5 行。

中心栏当前采用参考图思路：左边是人物和 9 件装备栏，下面是属性；右边是背包。9 件装备按 `3 + 3 + 3` 包围人物摆放。

### 改左/右功能面板

打开：

`scenes/main.tscn`

在节点树里找：

- `PanelRoot/LeftPanel/host_warehouse`
- `PanelRoot/LeftPanel/host_pet`
- `PanelRoot/LeftPanel/host_codex`
- `PanelRoot/LeftPanel/host_map`
- `PanelRoot/RightPanel/host_settings`
- `PanelRoot/RightPanel/host_reroll`
- `PanelRoot/RightPanel/host_detail`

这些 `host_*` 就是每个按钮打开的页面。你可以直接在里面移动 Label、Panel、TextureRect。

### 换图片

1. 把图片放到 `assets/ui/` 下面。
2. 在 Godot 里选中 `TextureRect`。
3. Inspector 里找到 `Texture`。
4. 拖入新图片。
5. 常用设置：
   - `Expand Mode`: Ignore Size 或 Fit Width/Height
   - `Stretch Mode`: Keep Aspect Centered

## 穿透测试流程

平时保持穿透开启。  
如果需要测试按钮点击，可以临时关闭：

1. 打开 `scenes/main.tscn`。
2. 选中 `PixelPassthrough`。
3. 在 Inspector 里把 `Enabled` 取消勾选。
4. 运行项目，测试点击。
5. 测完必须重新勾选 `Enabled`。

最终提交前要确认 `PixelPassthrough.Enabled` 是开启状态。

## 下一步建议

1. 把仓库、宠物、图鉴、地图、设置、洗练、详情继续拆成独立 `.tscn`，这样更适合新手逐页调整。
2. 把 PS 处理好的正式素材替换到 `TextureRect`。
3. 把仓库格子、装备格子、属性文字接入真实游戏数据。
4. 做按钮 hover、pressed、disabled 三种状态的正式贴图。
