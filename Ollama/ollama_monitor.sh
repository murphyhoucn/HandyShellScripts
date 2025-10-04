#!/bin/bash

# Ollama 运行状态监控脚本
# 用于实时监控Ollama服务和模型运行状态

SERVER_IP="x.x.x.x"  # 请替换为你的服务器IP地址
OLLAMA_PORT="x"  # 请替换为你的Ollama端口

# 配置
OLLAMA_API="http://$SERVER_IP:$OLLAMA_PORT"
REFRESH_INTERVAL=5  # 刷新间隔（秒）

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 清屏并显示标题
show_header() {
    clear
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}          Ollama 运行状态监控面板${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo -e "监控地址: ${GREEN}${OLLAMA_API}${NC}"
    echo -e "刷新间隔: ${GREEN}${REFRESH_INTERVAL}秒${NC} (按 Ctrl+C 退出)"
    echo ""
}

# 获取服务基本状态
get_service_status() {
    echo -e "${CYAN}=== 服务状态 ===${NC}"
    
    # 检查systemd服务状态
    if systemctl is-active --quiet ollama; then
        echo -e "🟢 Ollama服务: ${GREEN}运行中${NC}"
        local uptime=$(systemctl show ollama --property=ActiveEnterTimestamp --value)
        echo -e "📅 启动时间: ${GREEN}$(date -d "$uptime" '+%Y-%m-%d %H:%M:%S')${NC}"
    else
        echo -e "🔴 Ollama服务: ${RED}未运行${NC}"
        return 1
    fi
    
    # 检查进程
    local main_pid=$(pgrep -f "ollama serve")
    local runner_pids=$(pgrep -f "ollama runner")
    
    if [ -n "$main_pid" ]; then
        echo -e "🔧 主进程PID: ${GREEN}$main_pid${NC}"
    fi
    
    if [ -n "$runner_pids" ]; then
        echo -e "⚡ 运行器进程: ${GREEN}$(echo $runner_pids | wc -w)个${NC}"
    fi
    
    echo ""
}

# 获取GPU使用情况
get_gpu_status() {
    echo -e "${CYAN}=== GPU 使用状态 ===${NC}"
    
    if command -v nvidia-smi &> /dev/null; then
        # 获取GPU 2的信息（Ollama Config, Ref /etc/systemd/system/ollama.service.d/）
        local gpu_info=$(nvidia-smi --query-gpu=index,name,temperature.gpu,power.draw,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits | sed -n '3p')
        
        if [ -n "$gpu_info" ]; then
            IFS=',' read -r index name temp power mem_used mem_total util <<< "$gpu_info"
            
            echo -e "🎮 GPU ${index} (${name// /})"
            echo -e "🌡️  温度: ${GREEN}${temp// /}°C${NC}"
            echo -e "⚡ 功耗: ${GREEN}${power// /}W${NC}"
            echo -e "💾 显存: ${GREEN}${mem_used// /}MB${NC} / ${mem_total// /}MB ($(( (${mem_used// /} * 100) / ${mem_total// /} ))%)"
            echo -e "📊 利用率: ${GREEN}${util// /}%${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  nvidia-smi 未安装${NC}"
    fi
    
    echo ""
}

# 获取当前运行的模型
get_running_models() {
    echo -e "${CYAN}=== 当前运行模型 ===${NC}"
    
    local response=$(curl -s --connect-timeout 3 "${OLLAMA_API}/api/ps" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        local models=$(echo "$response" | jq -r '.models[]? | "\(.name)|\(.size)|\(.size_vram)|\(.expires_at)|\(.context_length)"' 2>/dev/null)
        
        if [ -n "$models" ] && [ "$models" != "null" ]; then
            echo "$models" | while IFS='|' read -r name size size_vram expires_at context_length; do
                echo -e "🤖 模型: ${GREEN}$name${NC}"
                echo -e "📦 模型大小: ${GREEN}$(( size / 1024 / 1024 ))MB${NC}"
                echo -e "💾 显存占用: ${GREEN}$(( size_vram / 1024 / 1024 ))MB${NC}"
                echo -e "⏰ 过期时间: ${GREEN}$(date -d "$expires_at" '+%H:%M:%S' 2>/dev/null || echo "N/A")${NC}"
                echo -e "📝 上下文长度: ${GREEN}$context_length${NC}"
                echo ""
            done
        else
            echo -e "${YELLOW}📭 当前没有运行中的模型${NC}"
            echo ""
        fi
    else
        echo -e "${RED}❌ 无法连接到Ollama API${NC}"
        echo ""
    fi
}

# 获取可用模型列表
get_available_models() {
    echo -e "${CYAN}=== 可用模型列表 ===${NC}"
    
    local response=$(curl -s --connect-timeout 3 "${OLLAMA_API}/api/tags" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        local models=$(echo "$response" | jq -r '.models[]? | "\(.name)|\(.size)|\(.modified_at)"' 2>/dev/null)
        
        if [ -n "$models" ] && [ "$models" != "null" ]; then
            echo "$models" | while IFS='|' read -r name size modified_at; do
                echo -e "📚 ${GREEN}$name${NC} ($(( size / 1024 / 1024 ))MB)"
            done
        else
            echo -e "${YELLOW}📭 没有找到可用模型${NC}"
        fi
    else
        echo -e "${RED}❌ 无法获取模型列表${NC}"
    fi
    
    echo ""
}

# 获取系统资源使用情况
get_system_resources() {
    echo -e "${CYAN}=== 系统资源 ===${NC}"
    
    # CPU使用率
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo -e "🖥️  CPU使用率: ${GREEN}${cpu_usage}%${NC}"
    
    # 内存使用率
    local mem_info=$(free | grep Mem)
    local mem_used=$(echo "$mem_info" | awk '{print $3}')
    local mem_total=$(echo "$mem_info" | awk '{print $2}')
    local mem_percent=$(( (mem_used * 100) / mem_total ))
    echo -e "💻 内存使用率: ${GREEN}${mem_percent}%${NC} ($(( mem_used / 1024 / 1024 ))GB / $(( mem_total / 1024 / 1024 ))GB)"
    
    # 磁盘使用情况
    local disk_usage=$(df -h /usr/share/ollama 2>/dev/null | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    if [ -n "$disk_usage" ]; then
        echo -e "💿 模型存储: ${GREEN}${disk_usage}%${NC}"
    fi
    
    echo ""
}

# 实时监控模式
monitor_mode() {
    while true; do
        show_header
        get_service_status
        get_gpu_status
        get_running_models
        get_available_models
        get_system_resources
        
        echo -e "${PURPLE}下次刷新: $(date -d "+${REFRESH_INTERVAL} seconds" '+%H:%M:%S')${NC}"
        sleep $REFRESH_INTERVAL
    done
}

# 单次状态检查
status_check() {
    show_header
    get_service_status
    get_gpu_status
    get_running_models
    get_available_models
    get_system_resources
}

# GPU详细信息
gpu_detail() {
    echo -e "${BLUE}=== GPU详细信息 ===${NC}"
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi -i 2 --query-gpu=index,name,driver_version,temperature.gpu,power.draw,power.limit,memory.used,memory.total,utilization.gpu,utilization.memory --format=csv
    else
        echo -e "${RED}nvidia-smi 未安装${NC}"
    fi
}

# 显示帮助
show_help() {
    echo "Ollama监控工具使用说明："
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  monitor, -m     实时监控模式 (默认)"
    echo "  status, -s      单次状态检查"
    echo "  gpu, -g         显示GPU详细信息"
    echo "  models, -l      只显示模型信息"
    echo "  help, -h        显示此帮助信息"
    echo ""
    echo "环境变量:"
    echo "  OLLAMA_API      Ollama API地址 (默认: http://:$OLLAMA_PORT)"
    echo "  REFRESH_INTERVAL 刷新间隔秒数 (默认: 5)"
}

# 只显示模型信息
models_only() {
    get_running_models
    get_available_models
}

# 主程序
main() {
    case "$1" in
        "monitor"|"-m"|"")
            monitor_mode
            ;;
        "status"|"-s")
            status_check
            ;;
        "gpu"|"-g")
            gpu_detail
            ;;
        "models"|"-l")
            models_only
            ;;
        "help"|"-h")
            show_help
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 检查依赖
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}警告: 未安装jq，某些功能可能受限${NC}"
    echo "安装命令: sudo apt install jq"
    echo ""
fi

# 捕获Ctrl+C信号
trap 'echo -e "\n${GREEN}监控已停止${NC}"; exit 0' INT

# 运行主程序
main "$@"