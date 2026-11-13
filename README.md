# 最后的防线 / Last Defense

一款使用 **Godot 4.7** 开发的俯视角自动战斗 Roguelite 原型。

玩家控制最后一台防卫机器人，在动态战场中保护能源核心，拾取经验、组合武器、使用地图终端，并在最终阶段击败攻城泰坦。

> 当前状态：可完整游玩的 Windows / Godot MVP，使用 AI 生成的占位美术和程序生成音效，适合学习、试玩与继续迭代。

## 核心特色

- 只控制移动，武器自动索敌攻击
- 能量炮、电弧模块、环绕刀片三种武器
- 九类升级与两种武器融合
- 普通、快速、重型、精英和 Boss 敌人
- 机械柱、腐蚀区、减速区构成的动态战场
- 维修、超载、医疗三种可互动终端
- 核心突袭、精英入侵、终端重置随机事件
- Boss 冲锋预警、召唤小怪与完整胜负结算
- 首次游玩四步训练引导与三阶段战况提示
- 标题、暂停、升级和结算界面
- 屏幕震动、伤害数字、受击反馈与程序生成音效

## 操作

| 按键 | 功能 |
| --- | --- |
| `Enter` | 开始游戏 / 继续游戏 |
| `WASD` 或方向键 | 移动机器人 |
| `E` | 激活附近终端 |
| `1` / `2` / `3` | 选择升级 |
| `Esc` | 暂停 / 继续 |
| `M` | 开关音效 |
| `V` | 开关屏幕震动 |
| `F11` | 窗口 / 全屏切换 |
| `R` | 结算后重新开始 |
| `Q` | 暂停或结算时返回标题页 |
| `T` | 在标题页重新开启训练引导 |

武器会自动攻击最近的敌人。玩家或能源核心生命归零时失败；第 7 分钟 Boss 登场，击败 Boss 胜利，最迟第 10 分钟结算失败。

## 快速开始

### 使用 Godot 编辑器

1. 安装 Godot 4.7.x。
2. 打开 Godot 项目管理器。
3. 选择“导入”，定位仓库中的 `project.godot`。
4. 打开项目并按 `F6`，或点击右上角运行按钮。

### 命令行运行

Windows PowerShell：

```powershell
& "D:\Soft\Godot\Godot_v4.7.2-stable_win64.exe" --path "D:\Git\last-defense"
```

请根据自己的 Godot 和仓库位置调整路径。

## 文档

- [30 天逐日开发教程](docs/DAILY_TUTORIAL.md)
- [项目整体架构](docs/ARCHITECTURE.md)
- [完整玩法说明](docs/GAMEPLAY.md)
- [GitHub 上传与发布清单](docs/GITHUB_RELEASE.md)
- [开发日志](docs/DEVELOPMENT_LOG.md)

## 项目结构

```text
last-defense/
├── project.godot                 # Godot 项目配置
├── main.tscn                     # 主场景
├── main.gd                       # 当前 MVP 的主要游戏逻辑与绘制
├── assets/
│   ├── audio/                    # 程序生成的占位音效
│   └── sprites/generated/        # AI 生成原图与游戏用贴图
├── docs/                         # 教程、架构、玩法和发布文档
├── tests/
│   ├── smoke_test.gd             # 自动冒烟测试
│   └── inspect_assets.gd         # 图片透明通道检查
└── tools/
    ├── generate_audio.py         # 重新生成占位音效
    └── prepare_sprites.gd        # 裁切与缩放游戏贴图
```

当前版本为了快速验证玩法，将主要逻辑集中在 `main.gd`。这不是最终商业项目推荐结构；后续拆分方案见[架构文档](docs/ARCHITECTURE.md)。

## 自动测试

```powershell
& "D:\Soft\Godot\Godot_v4.7.2-stable_win64_console.exe" `
  --headless `
  --path "D:\Git\last-defense" `
  --script res://tests/smoke_test.gd
```

测试覆盖武器融合、Boss 生成、地图设施、精英敌人和终端激活等关键路径。

## 素材说明

- 玩家、敌人、Boss 和能源核心为 AI 生成的透明 PNG 占位素材。
- `*-v1.png` 是生成原图，`*-game-v1.png` 是游戏使用的 256×256 版本。
- 快速敌人复用普通敌人贴图并改变颜色。
- 音效由 `tools/generate_audio.py` 程序生成。
- 正式发布前应逐项确认所有素材、字体、音效及生成式内容的许可和平台规则。

## 开发状态

- [x] 核心移动与自动攻击
- [x] 经验、升级与武器融合
- [x] 三类基础武器
- [x] 动态关卡、障碍、危险区和终端
- [x] 随机事件、精英敌人和 Boss
- [x] 基础 UI、音效和战斗反馈
- [x] 自动冒烟测试
- [x] 战绩与设置持久化
- [x] 极端对象数量保护
- [x] 首次游玩引导、全屏与减震设置
- [ ] 正式动画与完整美术
- [ ] 数值平衡与性能分析
- [ ] 多人试玩与反馈统计
- [ ] Windows 导出包与公开 Demo

## 参与开发

欢迎通过 Issue 提交 Bug、平衡建议和玩法想法。提交代码前请先运行冒烟测试，并尽量保持一次提交只解决一个问题。

## License

本项目采用 [Apache License 2.0](LICENSE) 许可。你可以使用、修改和分发本项目，但需要遵守许可证中的版权、许可声明和其他条款。
