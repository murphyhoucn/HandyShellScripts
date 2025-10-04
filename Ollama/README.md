# Ollama 本地部署大模型相关脚本

# `ollama_monitor.sh`
**功能**: Ollama运行状态实时监控工具

**主要功能**:
- 实时监控面板
- GPU使用状态
- 模型运行状态
- 系统资源监控
- 多种显示模式

``` bash
./ollama_monitor.sh -h

Ollama监控工具使用说明：

用法: ./ollama_monitor.sh [选项]

选项:
  monitor, -m     实时监控模式 (默认)
  status, -s      单次状态检查
  gpu, -g         显示GPU详细信息
  models, -l      只显示模型信息
  help, -h        显示此帮助信息

环境变量:
  OLLAMA_API      Ollama API地址 (默认: http://$SERVER_IP:$OLLAMA_PORT)
  REFRESH_INTERVAL 刷新间隔秒数 (默认: 5)
```



**使用方法**:
```bash
./ollama_monitor.sh              # 实时监控模式
./ollama_monitor.sh status       # 单次状态检查
./ollama_monitor.sh gpu          # GPU详细信息
./ollama_monitor.sh models       # 只显示模型信息
```

**监控内容**:
- **服务状态**: Ollama服务运行状态和进程信息
- **GPU状态**: 温度、功耗、显存使用率
- **模型状态**: 当前运行模型和过期时间
- **系统资源**: CPU、内存、磁盘使用情况

# `ollama_api_helper.sh`
**功能**: Ollama API配置和测试工具

**主要功能**:
- API连接信息显示
- 服务状态检查
- API功能测试
- 配置文件生成
- Zotero配置指南

**使用方法**:
```bash
./ollama_api_helper.sh info      # 显示API信息
./ollama_api_helper.sh status    # 检查服务状态
./ollama_api_helper.sh test      # 测试API连接
./ollama_api_helper.sh chat      # 测试聊天功能
./ollama_api_helper.sh config    # 生成配置文件
./ollama_api_helper.sh guide     # Zotero GPT 配置指南
./ollama_api_helper.sh check     # 全面检测
```

**核心功能**:
- **服务检测**: 检查Ollama服务和端口状态
- **API测试**: 验证模型列表和聊天功能
- **配置生成**: 创建标准化配置文件
- **集成指南**: 提供Zotero GPT插件配置说明

