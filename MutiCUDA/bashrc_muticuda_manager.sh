#!/bin/bash

# CUDA .bashrc 配置管理脚本
# 用于动态修改 .bashrc 中的默认CUDA版本配置

BASHRC_FILE="$HOME/.bashrc"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 用户配置 - 可根据需要修改
USER_NAME=$(whoami)
CUDA_BASE_PATH="/mnt/$USER_NAME"

# 支持的CUDA版本配置
declare -A CUDA_VERSIONS=(
    ["11.6"]="/mnt/$USER_NAME/cuda-11.6"
    ["12.1"]="/mnt/$USER_NAME/cuda-12.1"
    # 后续可以在这里添加更多版本
    # ["12.2"]="/mnt/$USER_NAME/cuda-12.2"
    # ["11.8"]="/mnt/$USER_NAME/cuda-11.8"
)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示使用方法
show_usage() {
    echo "CUDA .bashrc 配置管理器"
    echo ""
    echo "用法: $0 <command> [version]"
    echo ""
    echo "命令:"
    echo "  set <version>    设置默认CUDA版本并更新.bashrc"
    echo "  show             显示当前.bashrc中的CUDA配置"
    echo "  list             列出所有支持的CUDA版本"
    echo "  backup           备份当前.bashrc"
    echo "  restore <file>   恢复.bashrc备份"
    echo "  add <ver> <path> 添加新的CUDA版本支持"
    echo ""
    echo "支持的版本:"
    for version in "${!CUDA_VERSIONS[@]}"; do
        local path="${CUDA_VERSIONS[$version]}"
        if [ -d "$path" ]; then
            echo "  $version ✓ ($path)"
        else
            echo "  $version ✗ ($path - 路径不存在)"
        fi
    done
    echo ""
    echo "示例:"
    echo "  $0 set 12.1      # 设置默认CUDA为12.1版本"
    echo "  $0 show          # 显示当前配置"
    echo "  $0 backup        # 备份.bashrc"
}

# 备份.bashrc
backup_bashrc() {
    local backup_dir="$HOME/BashrcBackup"
    
    # 检查备份目录是否存在，不存在则创建
    if [ ! -d "$backup_dir" ]; then
        mkdir -p "$backup_dir"
        print_info "已创建备份目录: $backup_dir"
    fi
    
    local backup_file="$backup_dir/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$BASHRC_FILE" "$backup_file"
    print_success "已备份 .bashrc 到: $backup_file"
    echo "$backup_file"
}

# 检查CUDA版本是否存在
check_cuda_version() {
    local version="$1"
    if [[ ! "${CUDA_VERSIONS[$version]+exists}" ]]; then
        print_error "不支持的CUDA版本: $version"
        print_info "支持的版本: ${!CUDA_VERSIONS[*]}"
        return 1
    fi
    
    local cuda_path="${CUDA_VERSIONS[$version]}"
    if [ ! -d "$cuda_path" ]; then
        print_error "CUDA $version 路径不存在: $cuda_path"
        return 1
    fi
    
    return 0
}

# 1. 获取当前.bashrc中的CUDA版本
get_current_cuda_version() {
    if grep -q "export CUDA_HOME=/mnt/$USER_NAME/cuda-" "$BASHRC_FILE" 2>/dev/null; then
        local current_version=$(grep "export CUDA_HOME=/mnt/$USER_NAME/cuda-" "$BASHRC_FILE" | sed 's/.*cuda-\([0-9.]*\).*/\1/')
        echo "$current_version"
    else
        echo ""
    fi
}

# 2. 检查系统中有哪些CUDA版本可用
check_available_cuda_versions() {
    print_info "检查系统中可用的CUDA版本..."
    local available_count=0
    for version in "${!CUDA_VERSIONS[@]}"; do
        local path="${CUDA_VERSIONS[$version]}"
        if [ -d "$path" ]; then
            print_success "  ✓ CUDA $version ($path)"
            ((available_count++))
        else
            print_warning "  ✗ CUDA $version ($path - 路径不存在)"
        fi
    done
    echo ""
    return $available_count
}

# 3. 检查指定版本是否可用
check_cuda_version_exists() {
    local version="$1"
    if [[ ! "${CUDA_VERSIONS[$version]+exists}" ]]; then
        print_error "不支持的CUDA版本: $version"
        print_info "支持的版本: ${!CUDA_VERSIONS[*]}"
        return 1
    fi
    
    local cuda_path="${CUDA_VERSIONS[$version]}"
    if [ ! -d "$cuda_path" ]; then
        print_error "CUDA $version 路径不存在: $cuda_path"
        return 1
    fi
    
    if [ ! -f "$cuda_path/bin/nvcc" ]; then
        print_error "CUDA $version nvcc不存在: $cuda_path/bin/nvcc"
        return 1
    fi
    
    return 0
}

# 显示当前配置
show_current_config() {
    print_info "=== 当前 .bashrc CUDA 配置 ==="
    
    local current_version=$(get_current_cuda_version)
    if [ -n "$current_version" ]; then
        print_info "默认CUDA版本: $current_version"
        local cuda_path="${CUDA_VERSIONS[$current_version]}"
        print_info "CUDA路径: $cuda_path"
        
        if [ -d "$cuda_path" ]; then
            print_success "路径存在 ✓"
            if [ -f "$cuda_path/bin/nvcc" ]; then
                local nvcc_version=$("$cuda_path/bin/nvcc" --version 2>/dev/null | grep "release" | sed 's/.*release \([^,]*\).*/\1/')
                print_info "nvcc版本: $nvcc_version"
            fi
        else
            print_warning "路径不存在 ✗"
        fi
    else
        print_warning "未找到CUDA配置，可能需要初始化"
    fi
    
    echo ""
    print_info "当前终端环境:"
    print_info "CUDA_HOME: ${CUDA_HOME:-未设置}"
    if command -v nvcc &> /dev/null; then
        local current_nvcc_version=$(nvcc --version 2>/dev/null | grep "release" | sed 's/.*release \([^,]*\).*/\1/')
        print_info "当前nvcc版本: $current_nvcc_version"
    else
        print_warning "nvcc命令不可用"
    fi
}

# 4. 清理系统中重复的CUDA环境变量
cleanup_current_cuda_env() {
    print_info "清理当前终端中的CUDA环境变量..."
    
    # 清理PATH中所有的CUDA路径
    if [ -n "$PATH" ]; then
        export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/mnt/$USER_NAME/cuda-' | tr '\n' ':' | sed 's/:$//')
    fi
    
    # 清理LD_LIBRARY_PATH中所有的CUDA路径
    if [ -n "$LD_LIBRARY_PATH" ]; then
        export LD_LIBRARY_PATH=$(echo "$LD_LIBRARY_PATH" | tr ':' '\n' | grep -v '/mnt/$USER_NAME/cuda-' | tr '\n' ':' | sed 's/:$//')
    fi
    
    # 清理CUDA环境变量
    unset CUDA_HOME
    unset CUDA_PATH
    
    print_success "环境变量清理完成"
}

# 5. 替换.bashrc中的CUDA版本
replace_cuda_version_in_bashrc() {
    local new_version="$1"
    
    print_info "替换 .bashrc 中的CUDA版本为: $new_version"
    
    # 使用简单的sed替换CUDA_HOME行
    sed -i "s|export CUDA_HOME=/mnt/$USER_NAME/cuda-[0-9.]*|export CUDA_HOME=/mnt/$USER_NAME/cuda-$new_version|g" "$BASHRC_FILE"
    
    print_success "已更新.bashrc中的CUDA版本"
}

# 核心设置函数：按照用户要求的逻辑
set_cuda_version() {
    local new_version="$1"
    
    print_info "=== 开始设置CUDA版本: $new_version ==="
    echo ""
    
    # 1. 备份当前的bashrc
    print_info "步骤1: 备份当前.bashrc"
    local backup_file=$(backup_bashrc)
    echo ""
    
    # 2. 找到当前的CUDA_HOME这一行，看一下当前设置的是什么版本
    print_info "步骤2: 检查当前.bashrc中的CUDA版本"
    local current_version=$(get_current_cuda_version)
    if [ -n "$current_version" ]; then
        print_info "当前版本: CUDA $current_version"
    else
        print_warning "未找到现有CUDA配置"
    fi
    echo ""
    
    # 3. 检查系统中有几个CUDA版本
    print_info "步骤3: 检查系统中可用的CUDA版本"
    check_available_cuda_versions
    
    # 4. 当前执行set的版本是不是安装了
    print_info "步骤4: 验证目标版本是否可用"
    if ! check_cuda_version_exists "$new_version"; then
        print_error "目标版本 CUDA $new_version 不可用，操作终止"
        return 1
    fi
    print_success "CUDA $new_version 验证通过"
    echo ""
    
    # 5. 清理当前环境中重复的CUDA环境变量
    print_info "步骤5: 清理重复的CUDA环境变量"
    cleanup_current_cuda_env
    echo ""
    
    # 6. 替换要set的版本
    print_info "步骤6: 更新.bashrc中的CUDA版本"
    replace_cuda_version_in_bashrc "$new_version"
    echo ""
    
    # 7. 结束，提醒用户运行source
    print_success "=== CUDA版本设置完成！ ==="
    print_info "✅ 已将CUDA版本设置为: $new_version"
    print_info "✅ 配置已保存到: ~/.bashrc"
    print_info "✅ 备份文件: $backup_file"
    echo ""
    print_info "💡 要在当前终端应用新配置，请执行: ${GREEN}source ~/.bashrc${NC}"
    print_info "💡 新打开的终端将自动使用 CUDA $new_version"
}

# 添加新的CUDA版本支持
add_cuda_version() {
    local version="$1"
    local path="$2"
    
    if [ -z "$version" ] || [ -z "$path" ]; then
        print_error "用法: $0 add <version> <path>"
        return 1
    fi
    
    if [ ! -d "$path" ]; then
        print_error "路径不存在: $path"
        return 1
    fi
    
    if [ ! -f "$path/bin/nvcc" ]; then
        print_warning "警告: $path/bin/nvcc 不存在，可能不是有效的CUDA安装路径"
    fi
    
    # 更新脚本中的CUDA_VERSIONS数组（这里只是提示，需要手动修改）
    print_info "请手动在脚本中添加以下配置："
    print_info "CUDA_VERSIONS[\"$version\"]=\"$path\""
    
    # 临时添加到当前会话
    CUDA_VERSIONS["$version"]="$path"
    print_success "已临时添加CUDA $version 支持 (本次运行有效)"
}

# 应用配置（重新加载.bashrc）
apply_config() {
    print_info "重新加载 .bashrc 配置..."
    
    # 清理当前CUDA环境变量
    unset CUDA_INITIALIZED
    unset CUDA_HOME
    unset CUDA_PATH
    
    # 重新source .bashrc
    source "$BASHRC_FILE"
    
    print_success "配置已应用！"
    print_info "新的CUDA环境:"
    print_info "CUDA_HOME: ${CUDA_HOME:-未设置}"
    
    if command -v nvcc &> /dev/null; then
        local nvcc_version=$(nvcc --version 2>/dev/null | grep "release" | sed 's/.*release \([^,]*\).*/\1/')
        print_success "nvcc版本: $nvcc_version"
    else
        print_warning "nvcc命令不可用"
    fi
}

# 主函数
main() {
    case "$1" in
        "set")
            if [ -z "$2" ]; then
                print_error "请指定CUDA版本"
                show_usage
                return 1
            fi
            
            set_cuda_version "$2"
            ;;
            
        "show")
            show_current_config
            ;;
            
        "list")
            print_info "支持的CUDA版本:"
            for version in "${!CUDA_VERSIONS[@]}"; do
                local path="${CUDA_VERSIONS[$version]}"
                if [ -d "$path" ]; then
                    print_success "  $version ✓ ($path)"
                else
                    print_warning "  $version ✗ ($path - 路径不存在)"
                fi
            done
            ;;
            
        "backup")
            backup_file=$(backup_bashrc)
            print_info "备份文件: $backup_file"
            ;;
            
        "restore")
            if [ -z "$2" ] || [ ! -f "$2" ]; then
                print_error "请指定有效的备份文件"
                return 1
            fi
            cp "$2" "$BASHRC_FILE"
            print_success "已恢复 .bashrc 从: $2"
            apply_config
            ;;
            
        "add")
            add_cuda_version "$2" "$3"
            ;;
            
        "help"|"-h"|"--help"|"")
            show_usage
            ;;
            
        *)
            print_error "未知命令: $1"
            show_usage
            return 1
            ;;
    esac
}

# 执行主函数
main "$@"