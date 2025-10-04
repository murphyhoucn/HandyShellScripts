#!/bin/bash

# Meow 代理自动化管理脚本
# 功能：启动Meow、检测代理连接状态、监控网络可达性

USER_NAME=$(whoami)

# 配置参数
CLASH_DIR="/mnt/$USER_NAME/meow"
CLASH_BINARY="$CLASH_DIR/meow"
CLASH_CONFIG="$CLASH_DIR/config.yaml"
TMUX_SESSION_NAME="meow"
PROXY_HOST="127.0.0.1"
PROXY_PORT="7890"
PROXY_URL="http://$PROXY_HOST:$PROXY_PORT"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 打印函数
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo -e "${PURPLE}[CLASH]${NC} $1"; }

# 测试网站列表
declare -A TEST_SITES=(
    ["Google"]="https://www.google.com"
    ["GitHub"]="https://github.com"
    ["YouTube"]="https://www.youtube.com"
    ["Twitter"]="https://twitter.com"
    ["OpenAI"]="https://openai.com"
    ["HuggingFace"]="https://huggingface.co"
    ["Aliyun"]="https://cn.aliyun.com/"
    ["TencentCloud"]="https://cloud.tencent.com/"
    ["Baidu"]="https://www.baidu.com"
)

# 检查依赖
check_dependencies() {
    local missing_deps=()
    
    if ! command -v tmux &> /dev/null; then
        missing_deps+=("tmux")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if [ ! -f "$CLASH_BINARY" ]; then
        missing_deps+=("meow binary at $CLASH_BINARY")
    fi
    
    if [ ! -f "$CLASH_CONFIG" ]; then
        missing_deps+=("meow config at $CLASH_CONFIG")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "缺少依赖: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# 检查Meow进程状态
check_meow_process() {
    if pgrep -f "$CLASH_BINARY" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# 检查tmux会话状态
check_tmux_session() {
    if tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 检查端口监听状态
check_proxy_port() {
    if netstat -tlln | grep -q ":$PROXY_PORT "; then
        return 0
    else
        return 1
    fi
}

# 启动Meow服务
start_meow() {
    print_header "启动Meow代理服务..."
    
    # 检查是否已经在运行
    if check_meow_process; then
        print_warning "Meow进程已在运行"
        return 0
    fi
    
    # 检查tmux会话
    if check_tmux_session; then
        print_info "tmux会话已存在，重新附加..."
        tmux kill-session -t "$TMUX_SESSION_NAME" 2>/dev/null
    fi
    
    # 启动新的tmux会话并运行Meow
    cd "$CLASH_DIR" || exit 1
    tmux new-session -d -s "$TMUX_SESSION_NAME" -c "$CLASH_DIR" "./meow -d ."
    
    # 等待服务启动
    print_info "等待Meow服务启动..."
    local retry_count=0
    local max_retries=10
    
    while [ $retry_count -lt $max_retries ]; do
        if check_proxy_port; then
            print_success "Meow服务启动成功！"
            return 0
        fi
        
        sleep 1
        ((retry_count++))
        echo -n "."
    done
    
    print_error "Meow服务启动失败，请检查配置"
    return 1
}

# 停止Meow服务
stop_meow() {
    print_header "停止Meow代理服务..."
    
    # 停止tmux会话
    if check_tmux_session; then
        tmux kill-session -t "$TMUX_SESSION_NAME"
        print_success "已停止tmux会话"
    fi
    
    # 停止Meow进程
    if check_meow_process; then
        pkill -f "$CLASH_BINARY"
        print_success "已停止Meow进程"
    fi
}

# 重启Meow服务
restart_meow() {
    print_header "重启Meow代理服务..."
    stop_meow
    sleep 2
    start_meow
}

# 测试单个网站连通性
test_site_connectivity() {
    local site_name="$1"
    local site_url="$2"
    local use_proxy="$3"
    
    local curl_cmd="curl --connect-timeout 5 --max-time 10 -s -I"
    
    if [ "$use_proxy" = "true" ]; then
        curl_cmd="$curl_cmd -x $PROXY_URL"
    fi
    
    if $curl_cmd "$site_url" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 检测代理连通性
test_proxy_connectivity() {
    print_header "检测代理连通性..."
    
    # 检查代理端口
    if ! check_proxy_port; then
        print_error "代理端口 $PROXY_PORT 未监听"
        return 1
    fi
    
    print_success "代理端口 $PROXY_PORT 正常监听"
    
    # 测试各个网站
    local success_count=0
    local total_count=${#TEST_SITES[@]}
    
    echo ""
    print_info "测试网站连通性："
    printf "%-15s %-10s %-10s %-10s\n" "网站" "直连" "代理" "状态"
    printf "%-15s %-10s %-10s %-10s\n" "----" "----" "----" "----"
    
    for site_name in "${!TEST_SITES[@]}"; do
        local site_url="${TEST_SITES[$site_name]}"
        
        # 测试直连
        local direct_status="❌"
        if test_site_connectivity "$site_name" "$site_url" "false"; then
            direct_status="✅"
        fi
        
        # 测试代理连接
        local proxy_status="❌"
        local final_status="失败"
        if test_site_connectivity "$site_name" "$site_url" "true"; then
            proxy_status="✅"
            final_status="成功"
            ((success_count++))
        fi
        
        printf "%-15s %-10s %-10s %-10s\n" "$site_name" "$direct_status" "$proxy_status" "$final_status"
    done
    
    echo ""
    print_info "连通性测试结果: $success_count/$total_count 成功"
    
    if [ $success_count -eq $total_count ]; then
        print_success "所有网站代理连接正常！"
        return 0
    elif [ $success_count -gt 0 ]; then
        print_warning "部分网站代理连接正常"
        return 0
    else
        print_error "所有网站代理连接失败"
        return 1
    fi
}

# 显示服务状态
show_status() {
    print_header "Meow服务状态"
    
    # Meow进程状态
    if check_meow_process; then
        print_success "Meow进程: 运行中"
        local pid=$(pgrep -f "$CLASH_BINARY")
        print_info "进程ID: $pid"
    else
        print_error "Meow进程: 未运行"
    fi
    
    # tmux会话状态
    if check_tmux_session; then
        print_success "tmux会话: 存在"
    else
        print_warning "tmux会话: 不存在"
    fi
    
    # 端口监听状态
    if check_proxy_port; then
        print_success "代理端口: $PROXY_PORT 监听中"
    else
        print_error "代理端口: $PROXY_PORT 未监听"
    fi
    
    # 环境变量状态
    if [ -n "$http_proxy" ] && [ -n "$https_proxy" ]; then
        print_success "环境变量: 已设置"
        print_info "http_proxy: $http_proxy"
        print_info "https_proxy: $https_proxy"
    else
        print_warning "环境变量: 未设置"
        print_info "建议运行: source ~/.bashrc"
    fi
}

# 监控模式
monitor_mode() {
    print_header "进入监控模式（每30秒检测一次，按Ctrl+C退出）"
    
    while true; do
        clear
        echo "=== Meow代理监控 - $(date) ==="
        echo ""
        
        show_status
        echo ""
        test_proxy_connectivity
        
        echo ""
        print_info "下次检测: 30秒后..."
        sleep 30
    done
}

# 查看tmux会话
view_meow_session() {
    if check_tmux_session; then
        print_info "附加到Meow tmux会话（按Ctrl+B然后D退出）"
        tmux attach-session -t "$TMUX_SESSION_NAME"
    else
        print_error "tmux会话不存在"
    fi
}

# 显示帮助信息
show_help() {
    echo "Meow 代理自动化管理脚本"
    echo ""
    echo "用法: $0 <command>"
    echo ""
    echo "命令:"
    echo "  start       启动Meow服务"
    echo "  stop        停止Meow服务"  
    echo "  restart     重启Meow服务"
    echo "  status      显示服务状态"
    echo "  test        测试代理连通性"
    echo "  monitor     进入监控模式"
    echo "  attach      附加到tmux会话"
    echo "  auto        自动启动并测试"
    echo "  help        显示此帮助信息"
    echo ""
    echo "配置信息:"
    echo "  Meow目录: $CLASH_DIR"
    echo "  代理地址: $PROXY_URL"
    echo "  tmux会话: $TMUX_SESSION_NAME"
    echo ""
    echo "示例:"
    echo "  $0 auto     # 自动启动Meow并测试连通性"
    echo "  $0 monitor  # 持续监控代理状态"
}

# 自动模式（启动并测试）
auto_mode() {
    print_header "自动启动Meow代理..."
    
    if ! check_dependencies; then
        exit 1
    fi
    
    # 启动服务
    if ! start_meow; then
        exit 1
    fi
    
    # 测试连通性
    echo ""
    test_proxy_connectivity
    
    # 显示状态
    echo ""
    show_status
    
    echo ""
    print_success "Meow代理自动配置完成！"
    print_info "使用 '$0 status'  查看Meow状态"
    print_info "使用 '$0 monitor' 进入监控模式"
    print_info "使用 '$0 attach'  查看Meow日志"
    print_info "使用 '$0 restart' 重启Meow服务"
}

# 主函数
main() {
    case "$1" in
        "start")
            if ! check_dependencies; then exit 1; fi
            start_meow
            ;;
        "stop")
            stop_meow
            ;;
        "restart")
            if ! check_dependencies; then exit 1; fi
            restart_meow
            ;;
        "status")
            show_status
            ;;
        "test")
            test_proxy_connectivity
            ;;
        "monitor")
            if ! check_dependencies; then exit 1; fi
            monitor_mode
            ;;
        "attach"|"tmux")
            view_meow_session
            ;;
        "auto")
            auto_mode
            ;;
        "help"|"-h"|"--help"|"")
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"