# 像素级桌面鼠标穿透 — 冻结记录

## 冻结时间

2026-06-26 14:00 (UTC+8)

## 冻结 HEAD

```
213ab08 feat: add pixel-level desktop mouse passthrough
```

## 技术方案

**Godot .NET 4.7 + C# + Windows API**

### 核心逻辑

1. 每帧通过 `DisplayServer.MouseGetPosition()` 获取鼠标屏幕坐标
2. 转换为 Godot 窗口内坐标
3. 通过 `Viewport.GetTexture().GetImage().GetPixel()` 读取该像素 Alpha
4. Alpha > 0.1（阈值）：移除 `WS_EX_TRANSPARENT`，窗口接收鼠标
5. Alpha ≤ 0.1：添加 `WS_EX_TRANSPARENT`，鼠标穿透到桌面/下层窗口
6. 仅状态变化时调用 `SetWindowLongPtr`，禁止每帧无脑切换

### 关键文件

| 文件 | 说明 |
|------|------|
| `scripts/DesktopPixelPassthrough.cs` | C# 像素穿透节点，134 行 |
| `roguefall.csproj` | .NET 项目文件 |
| `project.godot` | 新增 `[dotnet]` 配置节 |
| `scenes/main.tscn` | 挂载 DesktopPixelPassthrough 节点 |
| `scripts/main.gd` | **未触碰** |

### 禁止方案（永久冻结）

- ⛔ polygon 穿透方案
- ⛔ `DisplayServer.window_set_mouse_passthrough(polygon)`
- ⛔ 按 BattleBar / Panel / mode 拼矩形穿透
- ⛔ mode=0/1/2/4 分别写穿透逻辑
- ⛔ 近似区域穿透
- ⛔ 重写窗口系统

### Windows API

- `SetWindowLongPtr` / `GetWindowLongPtr`（64 位安全）
- 动态切换 `WS_EX_TRANSPARENT`
- 始终保留 `WS_EX_LAYERED`
- 窗口句柄来源：`DisplayServer.WindowGetNativeHandle`

## 用户手动验收结果

| 测试项 | 结果 |
|--------|------|
| 透明像素穿透到桌面/浏览器 | ✅ 通过 |
| 可见像素接收鼠标 | ✅ 通过 |
| BattleBar 可拖动 | ✅ 通过 |
| 面板可点击 | ✅ 通过 |
| 逻辑反转后穿透/接收正常 | ✅ 通过 |
| mode=0/1/2/4 正常 | ✅ 通过 |
| 窗口布局数学 | ✅ 未触碰 |
| 贴边/翻转/防抖 | ✅ 正常 |

## 后续禁令

1. 游戏内容开发（战斗/背包/装备/掉落/存档）不得触碰窗口布局数学
2. 不得将像素穿透方案回退为 polygon / 矩形方案
3. 不得按 mode 分别写穿透规则
4. 新增 UI 元素时，其透明区域应随整体 Viewport alpha 判断自动穿透，无需额外代码
