# GitHub 上传与发布清单

本文用于把本地项目整理成公开 GitHub 仓库。命令中的用户名、仓库地址和本地路径需要替换成你自己的内容。

## 1. 上传前检查

### 不要公开的内容

- 密码、Token、API Key 和登录信息
- 单位代码、客户数据和内部文档
- 个人身份证明、家庭信息和聊天记录
- 没有再分发权限的商业素材
- Godot 本地缓存 `.godot/`
- Windows 导出临时目录和日志

### 检查 Git 状态

```bash
git status --short
git diff --check
```

当前项目第一次提交时大部分文件会显示为未跟踪，这是正常现象；添加前应逐项确认。

## 2. 选择许可证

仓库已经采用 Apache License 2.0。下面的对比表保留用于理解不同许可证：

| 选择 | 适合情况 |
| --- | --- |
| MIT | 允许他人自由使用、修改和商业使用代码，只需保留声明 |
| Apache-2.0 | 与 MIT 类似，并包含明确专利授权条款 |
| GPL-3.0 | 修改和分发版本通常也必须保持开源 |
| 暂不添加 | 默认保留全部权利，他人可以阅读，但没有明确再利用授权 |

代码许可证不一定自动覆盖美术、音效和商标。可以在素材目录单独增加说明。

## 3. 第一次提交

```bash
git add .
git status --short
git commit -m "feat: publish Last Defense playable MVP"
```

提交前再次查看 `git status`，不要盲目提交整个磁盘或父目录。

## 4. 创建 GitHub 仓库

在 GitHub 创建空仓库，例如 `last-defense`。本地已经存在 README 和 Git 历史时，不要勾选在线初始化 README。

然后添加远程地址：

```bash
git branch -M main
git remote add origin https://github.com/<your-name>/last-defense.git
git push -u origin main
```

如果已经存在 `origin`：

```bash
git remote -v
git remote set-url origin https://github.com/<your-name>/last-defense.git
```

## 5. 建议的仓库信息

### Description

```text
A top-down auto-battler roguelite prototype built with Godot 4. Protect the last energy core, build weapon synergies, and defeat the siege titan.
```

### Topics

```text
godot godot4 gdscript roguelite survivor-game indie-game game-development
```

### About 页面

- 添加一张清晰的游戏截图。
- 添加 Demo 下载地址。
- 如果暂时没有在线页面，不需要填写 Website。

## 6. 截图与演示视频

README 最少建议加入：

1. 标题界面。
2. 普通战斗和升级界面。
3. 动态关卡终端与危险区。
4. Boss 战。

视频建议 20～40 秒，依次展示：

```text
移动与自动攻击 → 升级三选一 → 武器融合 → 使用终端 → Boss 冲锋
```

不要只录标题页，也不要使用包含个人通知、桌面文件或账号信息的全屏录制。

## 7. Windows 导出

在 Godot 中安装 Windows 导出模板，然后创建 Windows Desktop 预设。

建议输出结构：

```text
release/LastDefense-v0.1.0-windows/
├── LastDefense.exe
├── LastDefense.pck
└── README.txt
```

在另一台没有安装 Godot 的电脑上测试：

- 是否能启动。
- 图片和音效是否完整。
- 中文路径下是否能运行。
- 暂停、升级、Boss 和重开是否正常。

`release/` 可以不提交进 Git，而是在 GitHub Release 中上传压缩包。

## 8. 创建版本标签

```bash
git tag -a v0.1.0 -m "Playable MVP"
git push origin v0.1.0
```

建议 Release 标题：

```text
Last Defense v0.1.0 — Playable MVP
```

## 9. Release 说明模板

```markdown
## Last Defense v0.1.0

首个可完整游玩的公开原型。

### 已实现
- 三种自动武器和两种融合
- 动态防守关卡、危险区和终端
- 随机事件、精英敌人和最终 Boss
- 完整标题、暂停、升级和结算流程

### 操作
- WASD / 方向键：移动
- E：使用终端
- 1 / 2 / 3：选择升级
- Esc：暂停

### 已知问题
- 数值仍在测试中
- 当前美术和音效包含占位资源
- 大量敌人同时出现时可能产生性能波动

欢迎通过 Issue 提交反馈。
```

## 10. Issue 模板建议

Bug 反馈至少要求提供：

- Godot 版本或 Demo 版本
- Windows 版本
- 重现步骤
- 预期结果
- 实际结果
- 截图或日志

平衡建议至少说明：

- 使用的武器和升级
- 发生时间
- 认为过强或过弱的原因
- 是否完成 Boss 战

## 11. 每次发布前执行

```powershell
& "D:\Soft\Godot\Godot_v4.7.2-stable_win64_console.exe" `
  --headless `
  --path "D:\Git\last-defense" `
  --script res://tests/smoke_test.gd
```

随后检查：

- [ ] 自动测试通过
- [ ] 完整手动玩一局
- [ ] README 与实际功能一致
- [ ] 更新版本号和 Release Notes
- [ ] 在干净电脑测试 Windows 包
- [ ] 没有秘密信息和无授权素材
