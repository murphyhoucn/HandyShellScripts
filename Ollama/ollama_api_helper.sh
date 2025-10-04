#!/bin/bash

# Ollama API 管理工具
# 用于配置和测试Ollama API连接

# 服务器信息
SERVER_IP="x.x.x.x"  # 请替换为你的服务器IP地址
OLLAMA_PORT="x"  # 请替换为你的Ollama端口

BASE_URL="http://${SERVER_IP}:${OLLAMA_PORT}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示API连接信息
show_api_info() {
    echo -e "${BLUE}=== Ollama API 连接信息 ===${NC}"
    echo -e "服务器IP: ${GREEN}${SERVER_IP}${NC}"
    echo -e "端口: ${GREEN}${OLLAMA_PORT}${NC}"
    echo -e "API基础URL: ${GREEN}${BASE_URL}${NC}"
    echo ""
    echo -e "${YELLOW}Zotero GPT插件配置:${NC}"
    echo -e "  API URL: ${GREEN}${BASE_URL}${NC}"
    echo -e "  默认模型: ${GREEN}qwen3:8b${NC}"
    echo ""
}

# 检查服务状态
check_service() {
    echo -e "${BLUE}=== 检查Ollama服务状态 ===${NC}"
    
    # 检查服务是否运行
    if systemctl is-active --quiet ollama; then
        echo -e "✅ Ollama服务: ${GREEN}运行中${NC}"
    else
        echo -e "❌ Ollama服务: ${RED}未运行${NC}"
        return 1
    fi
    
    # 检查端口监听
    if netstat -tln | grep -q ":${OLLAMA_PORT}"; then
        echo -e "✅ 端口监听: ${GREEN}${OLLAMA_PORT}端口已开放${NC}"
    else
        echo -e "❌ 端口监听: ${RED}${OLLAMA_PORT}端口未监听${NC}"
        return 1
    fi
    
    echo ""
}

# 测试API连接
test_api() {
    echo -e "${BLUE}=== 测试API连接 ===${NC}"
    
    # 测试基本连接
    echo "测试基本连接..."
    if curl -s --connect-timeout 5 "${BASE_URL}/api/tags" > /dev/null; then
        echo -e "✅ API连接: ${GREEN}成功${NC}"
    else
        echo -e "❌ API连接: ${RED}失败${NC}"
        return 1
    fi
    
    # 测试模型列表
    echo "获取可用模型..."
    models=$(curl -s "${BASE_URL}/api/tags" | jq -r '.models[].name' 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$models" ]; then
        echo -e "✅ 可用模型:"
        echo "$models" | while read -r model; do
            echo -e "   ${GREEN}• $model${NC}"
        done
    else
        echo -e "❌ 获取模型列表失败"
        return 1
    fi
    
    echo ""
}

# 测试聊天功能
test_chat() {
    echo -e "${BLUE}=== 测试聊天功能 ===${NC}"
    
    local model=${1:-"qwen3:8b"}
    echo "使用模型: $model"
    echo "发送测试消息..."
    
    response=$(curl -s -X POST "${BASE_URL}/api/chat" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$model\",
            \"messages\": [{\"role\": \"user\", \"content\": \"你好，请简单介绍一下你自己\"}],
            \"stream\": false
        }")
    
    if [ $? -eq 0 ] && echo "$response" | jq -e '.message.content' > /dev/null 2>&1; then
        echo -e "✅ 聊天测试: ${GREEN}成功${NC}"
        echo -e "${YELLOW}模型回复:${NC}"
        echo "$response" | jq -r '.message.content' | head -3
        echo ""
    else
        echo -e "❌ 聊天测试: ${RED}失败${NC}"
        echo "错误响应: $response"
        return 1
    fi
}

# 生成配置文件
generate_config() {
    echo -e "${BLUE}=== 生成配置文件 ===${NC}"
    
    cat > ollama_api_config.json << EOF
{
    "api_url": "${BASE_URL}",
    "default_model": "qwen3:8b",
    "embedding_model": "all-minilm:latest",
    "timeout": 30,
    "max_tokens": 2048,
    "temperature": 0.7
}
EOF
    
    echo -e "✅ 配置文件已生成: ${GREEN}ollama_api_config.json${NC}"
    echo ""
}

# 显示Zotero配置指南
show_zotero_guide() {
    echo -e "${BLUE}=== Zotero GPT插件配置指南 ===${NC}"
    echo ""
    echo -e "${YELLOW}1. 安装Zotero GPT插件${NC}"
    echo "   • 下载插件 .xpi 文件"
    echo "   • 在Zotero中安装插件"
    echo ""
    echo -e "${YELLOW}2. 配置API设置${NC}"
    echo -e "   • API提供商: ${GREEN}Custom (自定义)${NC}"
    echo -e "   • API URL: ${GREEN}${BASE_URL}${NC}"
    echo -e "   • 模型名称: ${GREEN}qwen3:8b${NC}"
    echo -e "   • API Key: ${GREEN}(留空，本地模型不需要，若报错的话，可以输入一个空格)${NC}"
    echo ""
    echo -e "${YELLOW}3. 高级设置${NC}"
    echo "   • 最大tokens: 2048"
    echo "   • 温度参数: 0.7"
    echo "   • 超时时间: 30秒"
    echo ""
    echo -e "${YELLOW}4. 测试连接${NC}"
    echo "   • 在插件中点击'测试连接'"
    echo "   • 确保能成功连接到API"
    echo ""
}

# 主菜单
show_menu() {
    echo -e "${BLUE}=== Ollama API 管理工具 ===${NC}"
    echo "1. 显示API连接信息"
    echo "2. 检查服务状态"
    echo "3. 测试API连接"
    echo "4. 测试聊天功能"
    echo "5. 生成配置文件"
    echo "6. Zotero配置指南"
    echo "7. 全面检测"
    echo "0. 退出"
    echo ""
}

# 全面检测
full_check() {
    show_api_info
    check_service && test_api && test_chat
}

# 主程序
main() {
    case "$1" in
        "info"|"1")
            show_api_info
            ;;
        "status"|"2")
            check_service
            ;;
        "test"|"3")
            test_api
            ;;
        "chat"|"4")
            test_chat "$2"
            ;;
        "config"|"5")
            generate_config
            ;;
        "guide"|"6")
            show_zotero_guide
            ;;
        "check"|"7")
            full_check
            ;;
        "menu"|"")
            while true; do
                show_menu
                read -p "请选择操作 (0-7): " choice
                echo ""
                case $choice in
                    1) show_api_info ;;
                    2) check_service ;;
                    3) test_api ;;
                    4) 
                        read -p "输入模型名称 (默认: qwen3:8b): " model
                        test_chat "${model:-qwen3:8b}"
                        ;;
                    5) generate_config ;;
                    6) show_zotero_guide ;;
                    7) full_check ;;
                    0) echo "退出..."; exit 0 ;;
                    *) echo -e "${RED}无效选择${NC}" ;;
                esac
                echo ""
                read -p "按回车键继续..."
                clear
            done
            ;;
        *)
            echo "用法: $0 [命令]"
            echo "命令:"
            echo "  info/1    - 显示API连接信息"
            echo "  status/2  - 检查服务状态"
            echo "  test/3    - 测试API连接"
            echo "  chat/4    - 测试聊天功能"
            echo "  config/5  - 生成配置文件"
            echo "  guide/6   - Zotero配置指南"
            echo "  check/7   - 全面检测"
            echo "  menu      - 显示交互菜单 (默认)"
            ;;
    esac
}

# 检查依赖
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}警告: 未安装jq，某些功能可能受限${NC}"
    echo "安装命令: sudo apt install jq"
    echo ""
fi

# 运行主程序
main "$@"