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
    echo "  all      启动所有服务 (默认)"
    echo "  backend  启动后端API服务"
    echo "  game     启动游戏服务器"
    echo "  ai       启动AI服务"
    echo ""
    echo "示例:"
    echo "  $0          # 启动所有服务"
    echo "  $0 all      # 启动所有服务"
    echo "  $0 backend  # 仅启动后端服务"
    echo "  $0 game     # 仅启动游戏服务器"
    echo "  $0 ai       # 仅启动AI服务"
}

function check_service() {
    local service_name=$1
    local url=$2
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            print_status "$service_name 启动成功"
            return 0
        fi
        print_info "$service_name 启动中... (尝试 $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    print_error "$service_name 启动失败或超时"
    return 1
}

function check_if_running() {
    local service_name=$1
    local pid_file=$2
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            print_error "$service_name 已在运行 (PID: $pid)"
            return 1
        else
            rm -f "$pid_file"
        fi
    fi
    return 0
}

function start_backend() {
    print_info "启动后端服务..."
    
    if ! check_if_running "后端服务" "/root/zhixue/logs/backend.pid"; then
        return 1
    fi
    
    cd /root/zhixue/backend
    nohup go run cmd/server/main.go > ../logs/backend.log 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > ../logs/backend.pid
    
    # 检查服务启动状态
    check_service "API服务" "http://localhost:8001/health"
    
    if [ $? -eq 0 ]; then
        echo "  API服务:    http://localhost:8001 (PID: $BACKEND_PID)"
        echo "  健康检查:   curl http://localhost:8001/health"
        echo "  查看日志:   tail -f logs/backend.log"
    fi
}

function start_game() {
    print_info "启动游戏服务器..."
    
    if ! check_if_running "游戏服务器" "/root/zhixue/logs/game.pid"; then
        return 1
    fi
    
    cd /root/zhixue/backend
    nohup go run cmd/game/main.go > ../logs/game.log 2>&1 &
    GAME_PID=$!
    echo $GAME_PID > ../logs/game.pid
    
    print_status "游戏服务器启动完成"
    echo "  游戏服务器:  端口 8002 (PID: $GAME_PID)"
    echo "  端口检查:    netstat -tlnp | grep 8002"
    echo "  查看日志:    tail -f logs/game.log"
}

function start_ai() {
    print_info "启动AI服务..."
    
    if ! check_if_running "AI服务" "/root/zhixue/logs/ai.pid"; then
        return 1
    fi
    
    cd /root/zhixue/ai-service
    # 设置UTF-8环境变量并使用完整的虚拟环境Python路径
    PYTHONIOENCODING=utf-8 nohup ./venv/bin/python main.py > ../logs/ai.log 2>&1 &
    AI_PID=$!
    echo $AI_PID > ../logs/ai.pid
    
    # 检查服务启动状态
    check_service "AI服务" "http://localhost:8003/health"
    
    if [ $? -eq 0 ]; then
        echo "  AI服务:     http://localhost:8003 (PID: $AI_PID)"
        echo "  健康检查:   curl http://localhost:8003/health"
        echo "  查看日志:   tail -f logs/ai.log"
    fi
}

# 解析命令行参数
SERVICE=${1:-all}

# 验证参数
case $SERVICE in
    all|backend|game|ai)
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

echo "🚀 启动智学奇境服务 [$SERVICE]..."

# 创建日志目录
mkdir -p /root/zhixue/logs

# 根据参数启动对应的服务
case $SERVICE in
    all)
        echo ""
        start_backend
        echo ""
        start_game
        echo ""
        start_ai
        echo ""
        print_status "🎉 智学奇境所有服务启动完成！"
        echo ""
        echo "🔗 快速健康检查命令:"
        echo "  curl http://localhost:8001/health && curl http://localhost:8003/health"
        echo "  netstat -tlnp | grep -E '(8001|8003|8002)'"
        ;;
    backend)
        echo ""
        start_backend
        echo ""
        print_status "🎉 后端服务启动完成！"
        ;;
    game)
        echo ""
        start_game
        echo ""
        print_status "🎉 游戏服务器启动完成！"
        ;;
    ai)
        echo ""
        start_ai
        echo ""
        print_status "🎉 AI服务启动完成！"
        ;;
esac

echo ""
print_info "使用 './stop.sh $SERVICE' 停止服务"
