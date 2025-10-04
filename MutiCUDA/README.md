# MutiCUDA — CUDA .bashrc 配置管理脚本

## 总体介绍

`bashrc_muticuda_manager.sh` 是一个用于管理和切换用户 `~/.bashrc` 中默认 CUDA 版本的轻量级脚本。它通过在脚本中维护一个版本到路径的映射（`CUDA_VERSIONS`），完成：版本列出、验证、备份、替换和恢复等操作。该脚本适用于 Linux / WSL 等类 Unix 环境，默认使用 `/mnt/<USER>/cuda-<version>` 路径风格。

主要功能：
- 列出与显示当前 `~/.bashrc` 中的 CUDA 配置
- 备份与恢复 `~/.bashrc`
- 验证目标 CUDA 安装（检查目录与 `nvcc`）
- 将 `CUDA_HOME` 指向指定的 CUDA 版本并更新 `~/.bashrc`

## 用法

在终端中运行脚本：

```bash
# 从脚本所在目录运行
cd MutiCUDA
./bashrc_muticuda_manager.sh <command> [args]

# 或直接调用（示例：切换到 CUDA 12.1）
bash MutiCUDA/bashrc_muticuda_manager.sh set 12.1
```

主要命令：
- set <version>
  - 将 `~/.bashrc` 的 CUDA 配置切换到指定版本（会先备份）。
  - 示例：`./bashrc_muticuda_manager.sh set 12.1`

- show
  - 显示当前 `~/.bashrc` 中的 CUDA 配置与当前终端的 nvcc 状态。

- list
  - 列出脚本 `CUDA_VERSIONS` 中声明的所有受支持版本，并标注路径是否存在。

- backup
  - 备份当前 `~/.bashrc` 到 `$HOME/BashrcBackup/.bashrc.backup.YYYYMMDD_HHMMSS`。

- restore <file>
  - 从指定备份文件恢复 `~/.bashrc`，并会尝试重新加载配置。

- add <version> <path>
  - 临时在当前会话中添加一个版本映射（永久添加需编辑脚本中的 `CUDA_VERSIONS` 数组）。

- help / -h / --help
  - 显示帮助与使用说明。

## 注意事项

- 运行环境：该脚本为 Bash 脚本，设计用于类 Unix 环境（Linux、WSL、macOS）。在原生 Windows PowerShell/Command Prompt 上可能无法按预期运行。建议在 WSL 或 Git Bash 下使用。

- 路径风格：脚本默认使用 `/mnt/<USER>/cuda-<version>` 的路径格式，请根据你的系统调整 `CUDA_VERSIONS` 中的路径映射。

- 权限与可用性检查：脚本会检查目标路径是否存在并且是否含有 `bin/nvcc`；若缺失则会中止或发出警告。

- 修改与备份：执行 `set` 命令前会自动创建 `~/.bashrc` 的备份，发生问题可以使用 `restore` 恢复。请在恢复前确认备份文件的来源与完整性。

- sed 与兼容性：脚本使用 `sed -i` 原地替换 `~/.bashrc`。在 macOS 上，`sed -i` 的参数差异可能需要改为 `sed -i ''`。

- add 命令：`add` 命令对脚本内的 `CUDA_VERSIONS` 做临时修改，仅对当前运行有效；要永久添加版本，请直接编辑脚本并提交对应条目。

- 应用配置：脚本更新 `~/.bashrc` 后，当前 shell 不会自动生效。请运行 `source ~/.bashrc` 或打开新终端窗口以应用更改。

## 文件

- `bashrc_muticuda_manager.sh` — 主脚本，位于本目录。
