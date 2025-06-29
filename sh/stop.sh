#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

function print_error() {
    echo -e "${RED}❌ $1${NC}"
}

function print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

function print_usage() {
    echo "用法: $0 [服务名称]"
    echo ""
    echo "服务名称:"
    echo "  all      停止所有服务 (默认)"
    echo "  backend  停止后端API服务"
    echo "  game     停止游戏服务器"
    echo "  ai       停止AI服务"
    echo "  gateway  停止API网关"
    echo ""
    echo "示例:"
    echo "  $0          # 停止所有服务"
    echo "  $0 all      # 停止所有服务"
    echo "  $0 backend  # 仅停止后端服务"
    echo "  $0 game     # 仅停止游戏服务器"
    echo "  $0 ai       # 仅停止AI服务"
    echo "  $0 gateway  # 仅停止API网关"
}

function stop_by_pid() {
    local service_name=$1
    local pid_file=$2
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" 2>/dev/null
            sleep 2
            if kill -0 "$pid" 2>/dev/null; then
                kill -9 "$pid" 2>/dev/null
            fi
            print_status "$service_name 已停止 (PID: $pid)"
        else
            print_info "$service_name 进程不存在"
        fi
        rm -f "$pid_file"
    else
        print_info "$service_name PID文件不存在"
    fi
}

function stop_backend() {
    print_info "停止后端服务..."
    stop_by_pid "后端服务" "/root/zhixue/logs/backend.pid"
    
    # 备用方案：通过端口停止
    PID=$(lsof -ti:8001 2>/dev/null)
    if [ ! -z "$PID" ]; then
        kill -9 $PID 2>/dev/null
        print_status "端口 8001 进程已强制停止 (PID: $PID)"
    fi
}

function stop_game() {
    print_info "停止游戏服务器..."
    stop_by_pid "游戏服务器" "/root/zhixue/logs/game.pid"
    
    # 备用方案：通过端口停止
    PID=$(lsof -ti:8002 2>/dev/null)
    if [ ! -z "$PID" ]; then
        kill -9 $PID 2>/dev/null
        print_status "端口 8002 进程已强制停止 (PID: $PID)"
    fi
}

function stop_ai() {
    print_info "停止AI服务..."
    stop_by_pid "AI服务" "/root/zhixue/logs/ai.pid"
    
    # 备用方案：通过端口停止
    PID=$(lsof -ti:8003 2>/dev/null)
    if [ ! -z "$PID" ]; then
        kill -9 $PID 2>/dev/null
        print_status "端口 8003 进程已强制停止 (PID: $PID)"
    fi
}

function stop_gateway() {
    print_info "停止API网关..."
    stop_by_pid "API网关" "/root/zhixue/logs/gateway.pid"

    # 备用方案：通过端口停止
    PID=$(lsof -ti:8080 2>/dev/null)
    if [ ! -z "$PID" ]; then
        kill -9 $PID 2>/dev/null
        print_status "端口 8080 进程已强制停止 (PID: $PID)"
    fi
}

function stop_all() {
    print_info "正在停止所有服务..."
    stop_gateway
    stop_backend
    stop_game
    stop_ai
    print_status "所有服务已停止"
}

# 解析命令行参数
SERVICE=${1:-all}

# 验证参数
case $SERVICE in
    all|backend|game|ai|gateway)
        ;;
    -h|--help)
        print_usage
        exit 0
        ;;
    *)
        print_error "未知的服务名称: $SERVICE"
        echo ""
        print_usage
        exit 1
        ;;
esac

echo "🛑 停止智学奇境服务 [$SERVICE]..."

# 根据参数停止对应的服务
case $SERVICE in
    all)
        stop_all
        ;;
    backend)
        stop_backend
        ;;
    game)
        stop_game
        ;;
    ai)
        stop_ai
        ;;
    gateway)
        stop_gateway
        ;;
esac

echo ""
print_status "服务停止操作完成"
