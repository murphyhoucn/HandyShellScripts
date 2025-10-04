# Meow Proxy管理别名配置
# 添加到 ~/.bashrc 中以便快速使用

# Meow 管理别名
alias meow-start='/mnt/houjinliang/meow/meow_manager.sh start'
alias meow-stop='/mnt/houjinliang/meow/meow_manager.sh stop'
alias meow-restart='/mnt/houjinliang/meow/meow_manager.sh restart'
alias meow-status='/mnt/houjinliang/meow/meow_manager.sh status'
alias meow-test='/mnt/houjinliang/meow/meow_manager.sh test'
alias meow-monitor='/mnt/houjinliang/meow/meow_manager.sh monitor'
alias meow-auto='/mnt/houjinliang/meow/meow_manager.sh auto'
alias meow-attach='/mnt/houjinliang/meow/meow_manager.sh attach'

# 快捷Proxy函数
proxy-on() {
    /mnt/houjinliang/meow/meow_manager.sh auto
}

proxy-off() {
    /mnt/houjinliang/meow/meow_manager.sh stop
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
    echo "Proxy已关闭"
}

proxy-status() {
    /mnt/houjinliang/meow/meow_manager.sh status
}

# 显示使用说明
meow-help() {
    echo "Meow Proxy管理命令："
    echo ""
    echo "基本命令："
    echo "  meow-auto      自动启动并测试"
    echo "  meow-start     启动服务"
    echo "  meow-stop      停止服务"
    echo "  meow-status    显示状态"
    echo "  meow-test      测试连通性"
    echo "  meow-monitor   监控模式"
    echo "  meow-attach    查看日志"
    echo ""
    echo "快捷函数："
    echo "  proxy-on        启动Proxy"
    echo "  proxy-off       关闭Proxy"
    echo "  proxy-status    查看状态"
}