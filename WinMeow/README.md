# Windows 命令行代理工具

## test_meow_proxy.ps1 - Meow 代理连接测试脚本

### 功能
检测 Windows PowerShell 命令行环境下，通过 Meow 代理访问指定网站的连通性。

### 使用方法
```powershell
# 测试当前代理状态（默认）
.\WinCLI\test_meow_proxy.ps1

# 开启命令行代理环境变量并测试
.\WinCLI\test_meow_proxy.ps1 on

# 关闭命令行代理环境变量并测试  
.\WinCLI\test_meow_proxy.ps1 off

# 仅测试连接性
.\WinCLI\test_meow_proxy.ps1 test
```

### 测试网站列表
- Google
- GitHub  
- YouTube
- Twitter
- OpenAI
- HuggingFace
- Aliyun（阿里云）
- Baidu（百度）

### 输出说明
- **Direct**: 直连测试结果（OK/X）
- **Proxy**: 代理测试结果（OK/X）
- **Status**: 
  - `Proxy Works` - 代理可用（绿色）
  - `Direct Only` - 仅直连可用（黄色）
  - `Both Failed` - 都不可用（红色）

### 功能特性
- **代理开关控制**：通过 `on/off` 参数控制命令行代理环境变量
- **自动连接测试**：设置代理后自动检测各网站连通性
- **状态显示**：显示当前代理环境变量状态
- **彩色输出**：清晰的结果展示和状态提示

### 环境变量设置
使用 `on` 参数时，脚本会设置以下环境变量：
- `HTTP_PROXY=http://127.0.0.1:7890`
- `HTTPS_PROXY=http://127.0.0.1:7890` 
- `ALL_PROXY=http://127.0.0.1:7890`

这样 curl、git、npm 等命令行工具就会自动使用代理。

### 注意事项
- 默认代理地址：`127.0.0.1:7890`（Meow 默认端口）
- 如需修改端口，请编辑脚本中的 `$proxy` 变量
- 需要先启动 Meow 客户端
- 测试超时时间：8秒
- 环境变量设置仅在当前 PowerShell 会话有效
