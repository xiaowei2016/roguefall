# 冒险者挂机 - 本地环境配置

## Godot 引擎

| 项目 | 值 |
|------|-----|
| 引擎版本 | Godot 4.7 stable (Mono) |
| 可执行文件路径 | `D:\Projects\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64.exe` |
| 项目路径 | `D:\Projects\roguefall` |
| 渲染后端 | gl_compatibility |

## .NET SDK

| 项目 | 值 |
|------|-----|
| SDK 版本 | 8.0.422 |
| 安装路径 | `C:\Program Files\dotnet\dotnet.exe` |
| 目标框架 | net8.0 |
| Godot .NET SDK | Godot.NET.Sdk/4.7.0 |

## 验证命令

```bat
cd /d D:\Projects\roguefall
"D:\Projects\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64.exe" --headless --quit
dotnet build
```

## 环境记录日期

2026-06-26
