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
- `ui/pages/warehouse_panel.tscn`：左侧“仓库”页。
- `ui/pages/pet_panel.tscn`：左侧“宠物”页。
- `ui/pages/codex_panel.tscn`：左侧“图鉴”页。
- `ui/pages/map_panel.tscn`：左侧“地图”页。
- `ui/pages/settings_panel.tscn`：右侧“设置”页。
- `ui/pages/reroll_panel.tscn`：右侧“洗练”页。
- `ui/pages/detail_panel.tscn`：右侧“详情”页。
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
- `ui/pages/warehouse_panel.tscn -> Card/WarehouseScroll/Grid`：仓库格子。格子多了就继续往 `Grid` 里加 `Panel`。
- `ui/pages/pet_panel.tscn -> Card/PetScroll/PetList`：宠物信息和技能。技能多了就继续往 `PetList` 里加 `Panel`。
- `ui/pages/codex_panel.tscn -> Card/CodexScroll/List`：图鉴条目。图鉴多了就继续往 `List` 里加 `Label`。
- `ui/pages/map_panel.tscn -> Card/MapScroll/MapContent`：地图节点。节点多了就继续往 `MapContent` 里加 `Panel`。
- `ui/pages/settings_panel.tscn -> Card/SettingsScroll/Options`：设置选项。选项多了就继续往 `Options` 里加 `CheckBox` 或 `Label`。
- `ui/pages/reroll_panel.tscn -> Card/AttrScroll/AttrList`：洗练词条。词条多了就继续往 `AttrList` 里加 `Label`。
- `ui/pages/detail_panel.tscn -> Card/StatsScroll/Stats`：详情属性。属性多了就继续往 `Stats` 里加 `Label`。

外层 `ScrollContainer` 负责滑动，内层 `GridContainer` 或 `StatList` 负责排列。这样内容变多时不会挤坏面板。

## 物品详情弹窗

凡是有物品或装备的格子，都应该能看详情。现在已经做了两处：

- 中心背包页：`ui/root/center_main_panel.tscn -> ItemTooltip`
- 仓库页：`ui/pages/warehouse_panel.tscn -> ItemTooltip`
- 中心背包页已装备对比：`ui/root/center_main_panel.tscn -> EquippedTooltip`
- 仓库页已装备对比：`ui/pages/warehouse_panel.tscn -> EquippedTooltip`

交互规则：

1. 鼠标停在装备格、背包格、仓库格上 1 秒后，才显示详情弹窗，避免扫过格子时频繁弹出。
2. 点击格子会立刻显示并锁定弹窗，再点同一个格子会关闭。
3. 鼠标移开时，未锁定的弹窗会隐藏。
4. 锁定后点击页面空白区域也会关闭弹窗；中心背包页和仓库页都按这个规则。
5. 弹窗可以跨出当前小栏显示，但只允许在三栏面板高度内上下移动，不能遮挡底部战斗条。
6. 弹窗结构固定为：名称、类型、品质、战力或数量、基础属性、词条、说明。
7. 鼠标悬停格子时会变成亮金描边；点击锁定详情时会保持橙金描边，方便玩家知道当前正在查看哪个物品。
8. 装备位里的装备会显示 `卸下` 按钮；背包和仓库里的装备会显示 `装备` 按钮；背包里的消耗品、宝箱、宠物道具会显示 `使用` 按钮。
9. 背包或仓库里浏览装备时，会显示两个弹窗：一个是当前物品，一个是同类型已装备物品。这样不用把所有对比文字挤在同一个窗口里。
10. 当前物品弹窗优先贴着触发格子的右侧显示；右侧空间不够时显示到左侧。已装备弹窗会贴在当前物品弹窗旁边，两个弹窗都限制在三栏高度内，避免遮挡战斗条。
11. 已装备对比弹窗会显示该装备的全部词条，不只显示第一条；没有词条时显示 `词条：无`。

中心背包页的弹窗数据在 `ui/root/center_main_panel.gd` 的 `_slot_items` 里。
仓库页的弹窗数据在 `ui/pages/warehouse_panel.gd` 的 `_slot_items` 里。

中心背包页的 `装备` / `卸下` 已经接了最小可用的真实交换逻辑：

- 背包里点装备的 `装备`：会替换身上同类型装备，原装备回到刚才的背包格。
- 装备位点 `卸下`：会放到第一个空背包格。
- 仓库里点装备的 `装备`：会替换身上同类型装备，原装备回到刚才的仓库格；如果身上该部位为空，仓库格会空出来。
- 仓库页会读取中心装备位作为“已装备”对比来源，所以背包换装后，仓库里的对比弹窗也会跟着当前身上装备变化。

背包和仓库都有分类按钮：

- `全部`：显示所有有数据的物品格，也保留空格。
- `装备`：显示武器、防具、饰品等装备。
- `消耗`：显示消耗品、宝箱、宠物道具等可用物品。
- `其他`：显示材料、任务、探索道具等其它物品。

仓库页现在有 `整理` 按钮，节点是 `ui/pages/warehouse_panel.tscn -> Card/SortButton`。点击后会按装备、消耗、材料、其他的顺序整理已有物品，空格会留在后面。

中心背包页也有 `整理` 按钮，节点是 `ui/root/center_main_panel.tscn -> BagPanel/SortButton`。点击后会按装备、消耗、材料、其他的顺序整理背包物品，不会影响人物身上的 9 个装备位。

中心背包页的 `快速使用` 按钮，节点是 `ui/root/center_main_panel.tscn -> BagPanel/UseButton`。如果当前锁定的是消耗品、宝箱或宠物道具，会优先使用当前物品；如果没有锁定可用物品，会自动使用背包里第一个可用物品。使用后会扣数量，数量归零时清空该背包格。

点开背包里的消耗品、宝箱或宠物道具详情时，弹窗底部也会显示 `使用` 按钮，逻辑和 `快速使用` 一样：扣数量，数量归零时清空该背包格。

背包和仓库现在支持最小可用的互相存取：

- 背包里的材料、任务、探索道具等非装备且不可直接使用的物品，详情弹窗会显示 `存入`，点击后进入仓库第一个空格。
- 仓库里的材料、宠物道具、探索道具等非装备物品，详情弹窗会显示 `取出`，点击后进入背包第一个空格。
- 装备在仓库里仍然优先显示 `装备`，用于直接替换身上同类型装备。

后面只要新增新的物品格子，就按这个规则补一条 `_slot_items` 数据，否则玩家看不到这个物品是什么。

中心角色身上的 9 个装备位现在都应该同时具备两样东西：

- 场景里有图标节点：例如 `HeroCard/SlotBottom1/Icon`。
- 脚本里有详情数据：例如 `ui/root/center_main_panel.gd -> _slot_items -> "SlotBottom1"`。

如果只加图标不加 `_slot_items`，玩家看不到装备详情；如果只加 `_slot_items` 不加图标，玩家会觉得格子是空的。

`main.tscn` 里的左侧和右侧功能页现在都是 `ui/pages/` 下面的独立实例。你要调某个页面外观时，优先打开对应页面文件，不要在主场景里一层层找。

页面对应关系：

- 仓库：`ui/pages/warehouse_panel.tscn`
- 宠物：`ui/pages/pet_panel.tscn`
- 图鉴：`ui/pages/codex_panel.tscn`
- 地图：`ui/pages/map_panel.tscn`
- 设置：`ui/pages/settings_panel.tscn`
- 洗练：`ui/pages/reroll_panel.tscn`
- 详情：`ui/pages/detail_panel.tscn`

侧边页现在也按“一个页面一个场景”的方式整理好了：

- 仓库页：主要改 `Card/WarehouseScroll/Grid`，适合放仓库格子。
- 宠物页：主要改 `Card/PetScroll/PetList`，适合放宠物头像、名字、技能、亲密度。
- 图鉴页：主要改 `Card/CodexScroll/List`，适合放图鉴条目。
- 地图片：主要改 `Card/MapScroll/MapContent`，适合放地图节点。
- 设置页：主要改 `Card/SettingsScroll/Options`，适合放开关、音量滑条和设置文字。
- 洗练页：主要改 `Card/AttrScroll/AttrList`，适合放装备词条。

这些页面外层都有 `ScrollContainer`，内容变多时会滚动，不需要把面板强行拉大。

宠物页常改节点：

- `Card/PetScroll/PetList/Status`：当前出战状态。
- `Card/PetScroll/PetList/PetIcon`：宠物头像。
- `Card/PetScroll/PetList/SkillA`、`SkillB`：宠物技能卡。
- `Card/PetScroll/PetList/AffinityBar`：亲密度进度条。
- `Card/PetScroll/PetList/ActionRow/FeedButton`、`DeployButton`：喂养和出战入口。
- `ui/pages/pet_panel.gd`：当前只做 UI 演示反馈。点击喂养会增加亲密度条，点击出战会把按钮变成已出战。

图鉴页常改节点：

- `Card/CodexScroll/List/Entry1` 到 `Entry6`：图鉴条目。
- `Card/Progress`：总收集进度文字。
- `Card/ProgressBar`：总收集进度条。
- `Card/RewardButton`：领取图鉴奖励入口。
- `ui/pages/codex_panel.gd`：当前只做 UI 演示反馈。点击领取后按钮会变成已领取。

地图页常改节点：

- `Card/MapScroll/MapContent/RouteTitle`：当前区域文字。
- `NodeA`、`NodeB`、`NodeC`：地图节点。当前节点用金色，普通节点用蓝色，未解锁节点用灰色。
- `RouteLineAB`、`RouteLineBC`：节点之间的路线线条。
- `Card/EnterButton`：进入当前区域按钮。
- `ui/pages/map_panel.gd`：当前只做 UI 演示反馈。点击进入后会显示巡逻中。

洗练页常改节点：

- `Card/Title`：当前选择的装备名。
- `Card/EquipPanel/EquipInfo`：装备品质、等级、洗练槽摘要。
- `Card/AttrScroll/AttrList/Attr1` 到 `Attr6`：词条行。
- 每个词条行里的 `Label`：词条文字。
- 每个词条行里的 `Lock`：锁定勾选框。
- `Card/Cost`：本次洗练消耗。
- `Card/Preview`：锁定数量和操作提示。
- `Card/ActionButton`：开始洗练按钮。
- `ui/pages/reroll_panel.gd`：当前只做 UI 演示反馈。点击开始洗练会保留已勾选锁定的词条，并替换未锁定词条文字。

注意：当前洗练页先做 UI 架构和入口。正式随机洗练逻辑要等装备词条库和装备生成稳定后再接入，避免临时生成文档外的词条。

设置页音量节点：

- `MasterVolumeLabel` / `MasterVolumeSlider`：主音量。
- `MusicVolumeLabel` / `MusicVolumeSlider`：背景音乐音量。
- `SfxVolumeLabel` / `SfxVolumeSlider`：音效音量。
- `ui/pages/settings_panel.gd`：运行时自动确保有 `Music` 和 `SFX` 音频总线，新手阶段不用先手动配置 Audio Bus。

详情页常改节点：

- `Header`：顶部蓝色标题条。
- `Card/PowerPanel/PowerLabel`：战力摘要，运行时会自动刷新。
- `Card/Tabs`：基础、战斗、收益三个分类标签，目前先作为视觉分区。
- `Card/StatsScroll/Stats`：可滚动属性列表，里面已经按 `基础属性`、`战斗属性`、`收益属性` 分组。
- `Card/GrowthPanel/GrowthLabel`：底部成长提示，运行时会自动刷新。
- `ui/pages/detail_panel.gd`：只负责点击基础、战斗、收益时切换显示哪一组属性。

详情页现在由 `ui/pages/detail_panel.gd -> refresh_from_game_data(data)` 统一刷新。`scripts/main.gd` 只负责把 `GameData` 传进去，不再逐行改详情页文字。这样你以后想改详情页时，主要看两个文件：

- 调视觉：打开 `ui/pages/detail_panel.tscn`。
- 调显示内容：打开 `ui/pages/detail_panel.gd`。

详情页属性行命名规则：

- `Stat1` 到 `Stat5`：基础属性。当前是等级、经验、生命、攻击、防御。
- `Stat6` 到 `Stat9`：战斗属性。
- `Stat10` 到 `Stat12`：收益属性。

如果要新增详情属性：

1. 打开 `ui/pages/detail_panel.tscn`。
2. 在 `Card/StatsScroll/Stats` 里复制一个同组的 `Label`。
3. 如果是基础属性，把它放到 `Stat1` 到 `Stat5` 附近。
4. 如果是战斗属性，把它放到 `Stat6` 到 `Stat9` 附近。
5. 如果是收益属性，把它放到 `Stat10` 到 `Stat12` 附近。
6. 之后再让我帮你把新属性接到数据刷新里。

现在点击 `基础`、`战斗`、`收益` 会切换显示对应分组。这个交互由 `ui/pages/detail_panel.gd` 控制，正常调视觉时不需要改它。

## 挂机战斗条

打开：

`scenes/GrasslandStage2D.tscn`

当前结构：

- `GrasslandStage2D`：整个 720 x 180 战斗条。
- `Frame`：透明裁剪窗口，只负责把可见区域限制在 720 x 180；它不是背景板。
- `Frame/world_root`：运行时横向世界，当前按 720 x 5 得到 3600 宽。
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

重要：素材按一屏 720 宽来做，不要把图片直接拉到 3600。运行时脚本会把 `segment_0_preview` 复制 5 段，形成 3600 宽横向世界。这样你的 PS 素材只需要按 720 x 180 的比例做，视觉比例不会被拉坏。

挂机逻辑是 3600 宽世界内左右折返找怪，不是打完一轮后重开。人物走到世界边缘会转身，怪物死亡后会刷在当前巡逻方向的前方；如果前方快到边缘，会自动换方向继续刷怪。

旧的整张草原合成预览图已经从场景里去除，避免误打开后压住分层。现在画面来源只看 `segment_0_preview` 里的分层节点。

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

外部素材目录是 `D:\Projects\素材\图片`，当前项目已经接入的素材放在这些位置：

- `assets/grassland/segment_sources/`：战斗条一屏分层素材，按 720 x 180 画面调位置。
- `assets/ui/icons/`：底部和侧栏功能按钮图标。
- `assets/ui/sheets/`：后续可切按钮、边框、面板贴图的大图。
- `assets/ui/_incoming/`：临时导入或等待整理的 UI 贴图。

建议流程：先在 PS 里把素材处理成透明 PNG，再复制到项目 `assets/` 下面，最后在 Godot 的对应 `TextureRect` 或 `TextureButton` 里替换。不要直接从 `D:\Projects\素材\图片` 引用，否则项目以后换电脑或移动目录时容易丢贴图。

## 穿透测试流程

平时保持穿透开启。

如果需要测试按钮点击，可以临时关闭：

1. 打开 `scenes/main.tscn`。
2. 选中 `PixelPassthrough`。
3. 在 Inspector 里把 `Enabled` 取消勾选。
4. 运行项目，测试点击。
5. 测完必须重新勾选 `Enabled`。

最终提交前要确认 `PixelPassthrough.Enabled` 是开启状态，`scenes/main.tscn` 里不能留下 `Enabled = false`。

## 按钮状态

常用按钮已经补了 Godot 原生三态样式：

- `normal`：平时状态。
- `hover`：鼠标移上去的状态。
- `pressed`：按下时的状态。
- `disabled`：不可点击状态。分类按钮当前选中时会进入 disabled，用来表示“当前页签”。

常改位置：

- 主界面底部和功能入口按钮：`scenes/main.tscn -> StyleBoxFlat_button_normal / hover / pressed / disabled`。
- 中心背包分类页签：`ui/root/center_main_panel.tscn -> StyleBoxFlat_tab / tab_hover / tab_pressed / tab_disabled`。
- 中心背包整理按钮：`StyleBoxFlat_blue_button / blue_button_hover / blue_button_pressed`。
- 中心背包快速使用和物品弹窗操作按钮：`StyleBoxFlat_gold_button / gold_button_hover / gold_button_pressed / button_disabled`。
- 仓库分类页签和整理、取出、装备按钮：`ui/pages/warehouse_panel.tscn` 里同名 StyleBox。

如果以后换正式按钮贴图，可以把这些 `Button` 换成 `TextureButton`；在现在的新手阶段，先用 StyleBoxFlat 更容易看懂和调颜色。

## 下一步建议

1. 你先继续在 `segment_0_preview` 里调天空、远山、村庄、地面等一屏分层位置。
2. 把 PS 处理好的玩家和怪物图替换到 `PlayerSprite`、`EnemySprite`。
3. 逐页打开 `ui/pages/` 里的功能页，按你的视觉稿微调位置和素材。
4. 后续如果有正式按钮图，再把当前 StyleBox 按钮替换为 TextureButton 多状态贴图。
