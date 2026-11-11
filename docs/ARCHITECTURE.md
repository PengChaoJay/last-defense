# 项目整体架构

本文描述《最后的防线》当前 MVP 的真实结构、运行流程、数据组织方式，以及从原型演进到可维护项目的推荐拆分方案。

## 1. 技术栈

| 项目 | 选择 |
| --- | --- |
| 引擎 | Godot 4.7.2 |
| 脚本 | GDScript |
| 渲染 | Compatibility / OpenGL 3.3 |
| 目标分辨率 | 1280×720 |
| 目标平台 | Windows PC |
| 外部依赖 | 无 |

项目没有后端、数据库、联网和第三方插件，适合作为个人开发的玩法验证项目。

## 2. 当前 MVP 架构

当前只有一个主要场景：

```text
main.tscn
└── LastDefense (Node2D)
    └── main.gd
        ├── 游戏状态
        ├── 玩家与核心
        ├── 敌人与 Boss
        ├── 武器与子弹
        ├── 经验与升级
        ├── 地图设施与事件
        ├── 音效管理
        └── 程序化界面和绘制
```

这是一个“集中式原型控制器”：实体以字典保存在数组中，画面通过 `_draw()` 统一绘制。优点是迭代快、文件少、容易复制；缺点是 `main.gd` 已经承担过多职责，不适合继续无限扩展。

## 3. 主循环

Godot 每帧调用 `_process(delta)`：

```text
输入与状态判断
    ↓
更新全局反馈和计时
    ↓
更新地图设施与随机事件
    ↓
更新玩家移动和障碍碰撞
    ↓
生成敌人 / Boss
    ↓
更新三种武器
    ↓
更新子弹、敌人、经验和特效
    ↓
检查胜利与失败
    ↓
queue_redraw() → _draw()
```

标题、暂停、升级和结算状态会提前返回，阻止战斗逻辑继续推进。

## 4. 状态模型

当前状态由几个布尔变量组合表达：

| 状态变量 | 含义 |
| --- | --- |
| `game_started` | 是否已从标题页开始游戏 |
| `game_paused` | 是否暂停 |
| `choosing_upgrade` | 是否正在三选一 |
| `game_over` | 是否已经结算 |
| `victory` | 结算是否为胜利 |
| `boss_spawned` | Boss 是否生成过 |
| `boss_alive` | Boss 是否存活 |

推荐在后续拆分时改为枚举状态机：

```gdscript
enum GameState { TITLE, PLAYING, UPGRADE, PAUSED, RESULT }
```

这样可以避免多个布尔变量组合出非法状态。

## 5. 数据组织

### 实体数组

```text
enemies       敌人和 Boss
bullets       能量弹
xp_orbs       经验晶体
sparks        粒子
arc_effects   电弧线
damage_numbers 伤害数字
```

数组中的每个元素是一个 `Dictionary`。例如敌人包含位置、生命、速度、半径、伤害、类型和若干冷却时间。

这种结构适合小规模灰盒，但缺乏静态类型和编辑器检查。正式拆分时应改成独立节点或自定义 Resource。

### 配置数据

- `upgrades`：九类升级卡定义。
- `obstacles`：六个机械柱的位置与半径。
- `hazards`：腐蚀区和减速区。
- `terminals`：三个终端的位置、冷却和颜色。

这些配置目前在运行时由代码创建。

## 6. 核心系统

### 玩家

`update_player()` 读取移动输入，应用减速效果，限制屏幕边界，最后通过 `resolve_player_obstacles()` 推出机械柱碰撞范围。

### 敌人

普通敌人根据玩家距离决定攻击玩家或核心。`steer_around_obstacles()` 添加排斥向量，形成轻量绕障；`resolve_enemy_obstacle()` 负责最后的穿透修正。

这不是完整寻路系统。复杂迷宫、多房间或狭窄通道应改用 Godot `NavigationRegion2D`。

### 武器

- `update_shooting()`：能量炮和多重射击。
- `update_arc_weapon()`：电弧攻击与弹射。
- `update_orbit_weapon()`：环绕刀片及接触冷却。
- `refresh_fusions()`：检查两种融合条件。

### 关卡

`update_arena_features()` 负责危险区、终端冷却、附近终端检测和随机事件计时。

### Boss

`update_boss_enemy()` 实现追踪、冲锋和召唤。冲锋前保存方向并由绘制层显示预警线。

### 表现层

所有画面由 `_draw()` 及 `draw_*()` 方法绘制。图片仅用于玩家、敌人、Boss 和核心；背景、障碍、危险区、UI 和特效为程序绘制。

## 7. 推荐的下一阶段目录

```text
last-defense/
├── scenes/
│   ├── game/game.tscn
│   ├── entities/player.tscn
│   ├── entities/enemy.tscn
│   ├── entities/boss.tscn
│   ├── combat/projectile.tscn
│   ├── pickups/xp_orb.tscn
│   └── ui/
├── scripts/
│   ├── core/game_manager.gd
│   ├── core/wave_director.gd
│   ├── combat/weapon_controller.gd
│   ├── combat/upgrade_manager.gd
│   ├── level/arena_controller.gd
│   └── ui/hud.gd
├── resources/
│   ├── enemies/
│   ├── weapons/
│   └── upgrades/
├── assets/
├── tests/
└── tools/
```

推荐拆分顺序：

1. 先把升级配置迁移到自定义 Resource。
2. 再把玩家、敌人、子弹改成独立场景。
3. 提取 `WaveDirector` 和 `UpgradeManager`。
4. 最后拆分 UI 和音效管理。

每拆一步都运行冒烟测试，避免一次重构全部系统。

## 8. 性能边界

当前自动索敌会遍历敌人数组，敌人和粒子也没有对象池。MVP规模可以接受，但敌人数量大幅提高后应进行以下优化：

- 降低索敌刷新频率，而不是每次攻击完整搜索。
- 使用空间分区或范围检测获取附近敌人。
- 为子弹、经验和粒子建立对象池。
- 给同时存活敌人设置硬上限。
- 使用 Godot Profiler 验证瓶颈后再优化。

## 9. 测试和工具

- `tests/smoke_test.gd`：覆盖升级、融合、终端、精英和 Boss 等关键路径。
- `tests/inspect_assets.gd`：检查生成图片的尺寸和透明通道。
- `tools/prepare_sprites.gd`：将生成原图裁切为游戏贴图。
- `tools/generate_audio.py`：生成无需外部依赖的占位音效。

## 10. 设计原则

1. 先验证一局是否有趣，再扩充内容。
2. 每个新增系统都必须改变玩家决策，而不只是增加数量。
3. 玩法参数和表现资源尽量解耦。
4. 保持可以随时导出、试玩和回滚。
5. 重构以测试保护为前提，不为“看起来专业”而提前复杂化。
