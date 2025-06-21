#!/bin/bash
# 智学奇境日志管理工具

LOG_DIR="/root/zhixue/logs"

function show_help() {
    echo "智学奇境日志管理工具"
    echo "使用方法:"
    echo "  $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  tail      实时查看日志"
    echo "  view      查看历史日志"
    echo "  clean     清理旧日志"
    echo "  analyze   日志分析"
    echo "  help      显示帮助"
    echo ""
    echo "选项:"
    echo "  -s, --service    指定服务 (backend|ai|all)"
    echo "  -l, --level      日志级别 (debug|info|warn|error)"
    echo "  -n, --lines      显示行数 (默认100)"
    echo ""
    echo "示例:"
    echo "  $0 tail -s backend     # 实时查看后端日志"
    echo "  $0 view -s ai -n 50    # 查看AI服务最近50行日志"
    echo "  $0 analyze             # 分析所有日志"
}

function tail_logs() {
    local service=$1
    
    case $service in
        "backend")
            echo "🔍 实时监控后端日志 (backend.log)..."
            tail -f $LOG_DIR/backend.log
            ;;
        "ai")
            echo "🔍 实时监控AI服务日志 (ai.log)..."
            tail -f $LOG_DIR/ai.log
            ;;
        "all")
            echo "🔍 实时监控所有日志..."
            tail -f $LOG_DIR/*.log
            ;;
        *)
            echo "❌ 未知服务: $service"
            echo "支持的服务: backend, ai, all"
            ;;
    esac
}

function view_logs() {
    local service=$1
    local lines=${2:-100}
    
    case $service in
        "backend")
            echo "📋 查看后端日志 (最近 $lines 行)..."
            tail -n $lines $LOG_DIR/backend.log
            ;;
        "ai")
            echo "📋 查看AI服务日志 (最近 $lines 行)..."
            tail -n $lines $LOG_DIR/ai.log
            ;;
        "all")
            echo "📋 查看所有日志 (最近 $lines 行)..."
            for log_file in $LOG_DIR/*.log; do
                if [ -f "$log_file" ]; then
                    echo "=== $(basename $log_file) ==="
                    tail -n $lines "$log_file"
                    echo ""
                fi
            done
            ;;
        *)
            echo "❌ 未知服务: $service"
            ;;
    esac
}

function clean_logs() {
    echo "🧹 清理旧日志文件..."
    
    # 删除7天前的压缩日志
    find $LOG_DIR -name "*.gz" -mtime +7 -delete
    
    # 显示当前日志目录大小
    echo "📊 当前日志目录大小:"
    du -sh $LOG_DIR
}

function analyze_logs() {
    echo "📊 日志分析报告"
    echo "=================="
    
    # 检查错误数量
    echo "🚨 错误统计:"
    if [ -f "$LOG_DIR/backend.log" ]; then
        echo "  后端错误: $(grep -c -i 'ERROR' $LOG_DIR/backend.log || echo 0)"
    fi
    if [ -f "$LOG_DIR/ai.log" ]; then
        echo "  AI服务错误: $(grep -c -i 'ERROR' $LOG_DIR/ai.log || echo 0)"
    fi
}

# --- Main script logic ---

if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

COMMAND=$1
shift

# Default values
SERVICE="all"
LINES=100

# Parse options
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -s|--service)
        SERVICE="$2"
        shift 2
        ;;
        -n|--lines)
        LINES="$2"
        shift 2
        ;;
        *)
        echo "错误: 未知选项 $1"
        show_help
        exit 1
        ;;
    esac
done

# Execute command
case $COMMAND in
    tail)
        tail_logs "$SERVICE"
        ;;
    view)
        view_logs "$SERVICE" "$LINES"
        ;;
    clean)
        clean_logs
        ;;
    analyze)
        analyze_logs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ 未知命令: $COMMAND"
        show_help
        ;;
esac
