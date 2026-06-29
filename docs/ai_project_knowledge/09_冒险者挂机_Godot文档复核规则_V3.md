# 冒险者挂机 Godot 4.7 官方文档强制复核规则 V3

> 项目名：冒险者挂机 | 引擎：Godot 4.7 | 路径：D:\Projects\roguefall
> 这是项目最高优先级规则之一，覆盖所有开发任务。

---

## 1. 最高规则（不可违背）

**任何Godot功能开发前必须先查官方文档 docs.godotengine.org/en/4.7 确认API用法。禁止凭经验/记忆/猜测调用API。**

### 1.1 强制复核场景

以下场景必须在编写代码前查阅Godot 4.7官方文档：

- 使用任何未在当前项目中验证过的Godot类/节点/API
- 涉及信号连接、资源加载、场景实例化等核心操作
- 涉及UI穿透、窗口透明、DisplayServer等系统级操作
- 涉及文件读写、存档序列化、JSON解析等数据操作
- 涉及shader、动画、粒子系统等渲染操作
- 修改已有代码中的Godot API调用

### 1.2 禁止行为

- 凭记忆使用Godot 3.x API（Godot 4.7有大量API变更）
- 凭其他引擎经验猜测Godot API
- 凭AI训练数据中可能过时的Godot API信息
- 不查文档直接使用运行时错误修复来"试"出正确API

---

## 2. F5 与 Headless 分工

| 验证类型 | 工具 | 用途 | 谁执行 |
|---|---|---|---|
| 编译/语法检查 | headless --quit | 检查脚本编译错误、资源引用完整性 | AI自动执行 |
| UI/交互验收 | F5运行 | 检查UI布局、动画、交互逻辑 | 人工执行 |

F5运行只用于人工验收UI/交互，不作为AI自动验证手段。Headless验证用于AI自动检查编译错误。

---

## 3. 回执必须包含官方文档复核章节

所有开发任务完成后，回执必须包含以下章节：

```text
【Godot 4.7 官方文档复核】
1. 查阅的文档URL列表（每行一个完整URL）
2. 核实的API/节点/类列表
3. 是否有API用法偏离官方文档的地方
4. 如有偏离：说明原因和影响范围
5. 结论：是否通过官方文档复核
```

---

## 4. 官方文档使用规范

### 4.1 访问方式
- 主站：https://docs.godotengine.org/en/4.7/
- 类参考：https://docs.godotengine.org/en/4.7/classes/

### 4.2 查阅优先级
1. 先查 Class Reference（类参考）确认API签名
2. 再查 Manual（手册）确认用法和最佳实践
3. 最后查 Tutorial（教程）确认场景示例

### 4.3 版本锁定
- 必须查阅 4.7 版本（URL中包含 `/en/4.7/`）
- 禁止引用 `latest` 或 `stable` 等可能版本漂移的路径
- 禁止引用 3.x 版本文档

---

## 5. 常见高风险API（开发前必查文档）

| API/功能 | 风险点 |
|---|---|
| DisplayServer.window_set_mouse_passthrough | 参数格式、坐标系统 |
| DisplayServer.window_set_flag | 标志枚举名、透明窗口要求 |
| ResourceLoader.load | 路径格式、线程安全 |
| PackedScene.instantiate | 返回类型、ownership设置 |
| JSON.parse_string | Godot 4.x新增，替代旧JSON解析方式 |
| FileAccess.open | Godot 4.x替代File类 |
| Tween.create_tween | Godot 4.x替代SceneTreeTween |
| signal connect | Godot 4.x使用Callable |
| @onready | 初始化时机、与_ready()的顺序 |
