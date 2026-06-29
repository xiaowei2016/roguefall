# Roguefall UI 新手制作计划

## 当前思路

项目使用 Godot 4 原生节点搭 UI。你主要在 Godot 编辑器里调整 `.tscn` 场景，不需要先写复杂代码。

窗口是透明桌面悬浮窗，核心布局分为四块：

1. `BattleBar`：底部 720 x 180 战斗条，常驻显示。
2. `CenterPanel`：中间 720 x 530 主面板，点击“背包”打开。
3. `LeftPanel`：左侧 352 x 530 功能面板，显示仓库、宠物、图鉴、地图。
4. `RightPanel`：右侧 352 x 530 功能面板，显示设置、洗练、详情。

## 主要文件

- `scenes/main.tscn`：总界面，负责窗口、三栏布局、按钮、功能页实例挂载。
- `ui/root/center_main_panel.tscn`：中心角色、装备、背包面板。
- `ui/pages/detail_panel.tscn`：右侧“详情”页，已经从主场景拆出来，适合单独打开调整。
- `scenes/GrasslandStage2D.tscn`：底部挂机战斗条里的草原场景。
- `scripts/grassland_stage_2d.gd`：挂机条里的横向世界、循环、找怪、攻击基础逻辑。
- `scripts/main.gd`：按钮切换、窗口位置、基础数据刷新。
- `scripts/DesktopPixelPassthrough.cs`：像素级穿透，不要随意删除。
- `assets/ui/icons/`：底部和面板标题图标。
- `assets/ui/_incoming/center_panel_back.png`：中心面板背景。

## 中心背包面板

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

中心栏当前按你的参考图思路做：左边是人物和 9 件装备栏，下面是属性；右边是背包。装备栏按 `3 + 3 + 3` 包围人物摆放。

属性和格子区域已经使用 Godot 原生滚动容器：

- `HeroCard/StatsScroll/StatList`：属性列表。属性多了就继续往 `StatList` 里加 `Label`。
- `BagPanel/BagScroll/BagGrid`：背包格子。格子多了就继续往 `BagGrid` 里加 `Panel`。
- `PanelRoot/LeftPanel/host_warehouse/Card/WarehouseScroll/Grid`：仓库格子。格子多了就继续往 `Grid` 里加 `Panel`。
- `PanelRoot/LeftPanel/host_codex/Card/CodexScroll/List`：图鉴条目。图鉴多了就继续往 `List` 里加 `Label`。
- `PanelRoot/RightPanel/host_reroll/Card/AttrScroll/AttrList`：洗练词条。词条多了就继续往 `AttrList` 里加 `Label`。
- `ui/pages/detail_panel.tscn -> Card/StatsScroll/Stats`：详情属性。属性多了就继续往 `Stats` 里加 `Label`。

外层 `ScrollContainer` 负责滑动，内层 `GridContainer` 或 `StatList` 负责排列。这样内容变多时不会挤坏面板。

`main.tscn` 里的 `PanelRoot/RightPanel/host_detail` 现在是 `detail_panel.tscn` 的实例。你要调详情页外观时，优先打开 `ui/pages/detail_panel.tscn`，不要在主场景里一层层找。

## 挂机战斗条

打开：

`scenes/GrasslandStage2D.tscn`

当前结构：

- `GrasslandStage2D`：整个 720 x 180 战斗条。
- `Frame`：透明裁剪窗口，只负责把可见区域限制在 720 x 180；它不是背景板。
- `Frame/world_root`：运行时横向世界，当前按 720 x 5 得到 3600 宽。
- `StageImage`：旧的整张合成预览图，默认隐藏；它只适合对照，不适合做分层底图。
- `Frame/world_root/segment_0_preview`：你自己调的 720 x 180 单屏多层场景模板。
- `sky_source_layer`、`mountain_source_layer`、`village_source_layer`、`ground_source_layer`、`grass_source_layer`、`tree_source_layer`：场景分层素材。
- `actor_layer`：人物、怪物、掉落、特效所在层。
- `player_anchor`：玩家位置锚点。
- `player_anchor/PlayerVisual`：玩家外观容器，翻转和后续动画作用在这里。
- `player_anchor/PlayerVisual/PlayerSprite`：以后放玩家图片的位置。
- `enemy_anchor`：怪物位置锚点。
- `enemy_anchor/EnemyVisual`：怪物外观容器，受击放大和闪白作用在这里。
- `enemy_anchor/EnemyVisual/EnemySprite`：以后放怪物图片的位置。

挂机条没有背景板。要做彩虹岛那种多层横向场景时，优先调 `segment_0_preview` 里面的分层节点。

重要：素材按一屏 720 宽来做，不要把图片直接拉到 3600。运行时脚本会把 `segment_0_preview` 复制 5 段，形成 3600 宽循环场景。这样你的 PS 素材只需要按 720 x 180 的比例做，视觉比例不会被拉坏。

如果你在画面里看到一张完整草原图压住其它层，检查 `StageImage.visible` 是否被打开了。正常状态下它应该是关闭的。

`GrasslandStage2D` 根节点 Inspector 里可以调这些脚本参数：

- `view_width`：可视窗口宽度，当前 720。
- `world_width`：横向世界宽度，运行时会按 `segment_width x segment_count` 自动得到，当前 3600。
- `segment_width`：单屏分段宽度，当前 720。
- `segment_count`：循环段数，当前 5。
- `ground_y`：人物和怪物站立高度。
- `camera_lead`：镜头跟随人物时预留的前方空间。
- `player_speed`：自动巡逻速度。
- `attack_range`：进入攻击的距离。
- `attack_interval`：自动攻击间隔。
- `walk_bob_height`：人物走路上下浮动幅度。

## 换图片

1. 把图片放到 `assets/ui/` 或对应的资源目录下面。
2. 在 Godot 里选中对应的 `TextureRect`。
3. Inspector 里找到 `Texture`。
4. 把新图片拖进去。
5. 常用设置：
   - `Expand Mode`: Ignore Size。
   - `Stretch Mode`: Keep Aspect Centered。

玩家图建议放到：

`scenes/GrasslandStage2D.tscn -> player_anchor -> PlayerVisual -> PlayerSprite`

怪物图建议放到：

`scenes/GrasslandStage2D.tscn -> enemy_anchor -> EnemyVisual -> EnemySprite`

临时色块只是占位，等正式图放进去以后可以隐藏或删除 `player_placeholder`、`player_head`、`enemy_placeholder`。

## 穿透测试流程

平时保持穿透开启。

如果需要测试按钮点击，可以临时关闭：

1. 打开 `scenes/main.tscn`。
2. 选中 `PixelPassthrough`。
3. 在 Inspector 里把 `Enabled` 取消勾选。
4. 运行项目，测试点击。
5. 测完必须重新勾选 `Enabled`。

最终提交前要确认 `PixelPassthrough.Enabled` 是开启状态，`scenes/main.tscn` 里不能留下 `Enabled = false`。

## 下一步建议

1. 你先继续在 `segment_0_preview` 里调天空、远山、村庄、地面等一屏分层位置。
2. 把 PS 处理好的玩家和怪物图替换到 `PlayerSprite`、`EnemySprite`。
3. 再把仓库、宠物、图鉴、地图、设置、洗练、详情拆成独立 `.tscn`，这样更适合新手逐页调整。
4. 最后给按钮补 hover、pressed、disabled 三种正式贴图状态。
