# Meow 代理自动化管理脚本

一个功能完整的Meow代理自动化管理工具，支持一键启动、智能检测和实时监控。

## 功能特性

- 🚀 **自动启动** - 通过tmux会话自动启动Meow服务
- 🔍 **智能检测** - 自动检测服务状态、端口监听和进程运行
- 🌐 **连通测试** - 测试Google、GitHub、YouTube等主要网站
- 📊 **实时监控** - 提供30秒间隔的实时状态监控
- 🎨 **彩色输出** - 清晰的状态显示和错误提示
- ⚙️ **完整管理** - 启动、停止、重启、状态查看等全套功能

## 目录结构

```
USER_NAME=$(whoami)

/mnt/$USER_NAME/meow/
├── meow                   # Meow可执行文件
├── config.yaml            # Meow配置文件
├── Country.mmdb           # IP地址数据库
├── meow_manager.sh       # 主管理脚本
├── meow_aliases.sh       # 快捷别名配置
└── README.md             # 使用说明
```

## 快速开始

### 1. 基本用法

```bash
# 进入Meow目录
cd /mnt/$USER_NAME/meow

# 自动启动并测试（推荐使用）
./meow_manager.sh auto

# 查看服务状态
./meow_manager.sh status

# 测试代理连通性
./meow_manager.sh test
```

### 2. 设置快捷别名（可选）

```bash
# 添加别名到.bashrc
echo "source /mnt/$USER_NAME/meow/meow_aliases.sh" >> ~/.bashrc
source ~/.bashrc

# 使用快捷命令
meow-auto      # 自动启动
meow-status    # 查看状态
proxy-on        # 快速启动代理
```

## 命令详解

### 主要命令

| 命令 | 功能 | 说明 |
|------|------|------|
| `auto` | 自动启动并测试 | 一键完成启动、检测、测试 |
| `start` | 启动Meow服务 | 通过tmux启动Meow |
| `stop` | 停止Meow服务 | 停止进程和tmux会话 |
| `restart` | 重启Meow服务 | 先停止再启动 |
| `status` | 显示服务状态 | 显示详细状态信息 |
| `test` | 测试代理连通性 | 测试多个网站连接 |
| `monitor` | 进入监控模式 | 每30秒自动检测状态 |
| `attach` | 附加到tmux会话 | 查看Meow实时日志 |

### 使用示例

```bash
# 完整启动流程
./meow_manager.sh auto

# 查看详细状态
./meow_manager.sh status

# 进入监控模式（按Ctrl+C退出）
./meow_manager.sh monitor

# 查看Meow日志（按Ctrl+B然后D退出）
./meow_manager.sh attach

# 重启服务
./meow_manager.sh restart
```

## 快捷别名

添加别名后可使用更简短的命令：

### 基本别名
```bash
meow-start      # 启动服务
meow-stop       # 停止服务
meow-restart    # 重启服务
meow-status     # 显示状态
meow-test       # 测试连通性
meow-monitor    # 监控模式
meow-auto       # 自动启动并测试
meow-attach     # 查看日志
```

### 快捷函数
```bash
proxy-on         # 启动代理
proxy-off        # 关闭代理并清除环境变量
proxy-status     # 查看代理状态
meow-help        # 显示帮助信息
```

## 监控功能

### 实时监控
```bash
./meow_manager.sh monitor
```

监控模式会显示：
- Meow进程状态
- tmux会话状态  
- 代理端口监听状态
- 环境变量设置状态
- 6个主要网站连通性测试

### 连通性测试

脚本会自动测试多个网站：
- **Google** - https://www.google.com
- **GitHub** - https://github.com
- **YouTube** - https://www.youtube.com
- **Twitter** - https://twitter.com
- **OpenAI** - https://openai.com
- **HuggingFace** - https://huggingface.co
- ……

测试结果显示：
- **直连状态** - 不使用代理的连接状态
- **代理状态** - 通过代理的连接状态
- **最终状态** - 综合判断结果

## 状态说明

### 服务状态指示

| 状态 | 图标 | 说明 |
|------|------|------|
| 成功 | ✅ | 功能正常工作 |
| 警告 | ⚠️ | 功能部分可用 |
| 错误 | ❌ | 功能不可用 |

### 输出颜色说明

- 🔵 **蓝色 [INFO]** - 信息提示
- 🟢 **绿色 [SUCCESS]** - 操作成功
- 🟡 **黄色 [WARNING]** - 警告信息
- 🔴 **红色 [ERROR]** - 错误信息
- 🟣 **紫色 [CLASH]** - Meow相关操作

## 故障排除

### 常见问题

1. **服务启动失败**
   ```bash
   # 检查配置文件
   ls -la /mnt/$USER_NAME/meow/config.yaml
   
   # 检查Meow二进制文件
   ls -la /mnt/$USER_NAME/meow/meow
   ```

2. **端口被占用**
   ```bash
   # 查看端口占用
   netstat -tlnp | grep 7890
   
   # 重启服务
   ./meow_manager.sh restart
   ```

3. **代理连接失败**
   ```bash
   # 检查环境变量
   echo $http_proxy $https_proxy
   
   # 重新加载环境变量
   source ~/.bashrc
   ```

4. **tmux会话问题**
   ```bash
   # 查看tmux会话
   tmux list-sessions
   
   # 强制停止会话
   tmux kill-session -t meow
   ```

### 依赖检查

脚本需要以下依赖：
- `tmux` - 会话管理
- `curl` - 网络测试
- `netstat` - 端口检查
- `meow` 可执行文件
- `config.yaml` 配置文件

## 配置信息

| 配置项 | 值 | 说明 |
|--------|----|----- |
| Meow目录 | `/mnt/$USER_NAME/meow` | Meow安装目录 |
| 代理地址 | `http://127.0.0.1:7890` | HTTP代理地址 |
| 管理端口 | `7891` | Meow管理端口 |
| tmux会话名 | `meow` | tmux会话名称 |

## 高级用法

### 开机自启动

```bash
# 添加到.bashrc开机启动
echo "/mnt/$USER_NAME/meow/meow_manager.sh start >/dev/null 2>&1" >> ~/.bashrc
```

### 定时检测

```bash
# 添加cron任务，每5分钟检测一次
echo "*/5 * * * * /mnt/$USER_NAME/meow/meow_manager.sh start >/dev/null 2>&1" | crontab -
```

### 日志查看

```bash
# 实时查看Meow日志
./meow_manager.sh attach

# 或直接使用tmux
tmux attach-session -t meow
```

## 注意事项

1. **权限要求** - 脚本需要启动进程的权限
2. **网络环境** - 需要有效的Meow配置文件
3. **系统资源** - tmux会话会持续占用少量系统资源
4. **代理配置** - 确保.bashrc中的代理环境变量正确设置

> *Meow = 🐱