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
            echo "🔍 实时监控后端日志..."
            tail -f $LOG_DIR/zhixue.log
            ;;
        "ai")
            echo "🔍 实时监控AI服务日志..."
            tail -f $LOG_DIR/ai_service.log
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
            tail -n $lines $LOG_DIR/zhixue.log
            ;;
        "ai")
            echo "📋 查看AI服务日志 (最近 $lines 行)..."
            tail -n $lines $LOG_DIR/ai_service.log
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
    if [ -f "$LOG_DIR/zhixue.log" ]; then
        echo "  后端错误: $(grep -c 'ERROR' $LOG_DIR/zhixue.log || echo 0)"
    fi
    
    if [ -f "$LOG_DIR/ai_service.log" ]; then
        echo "  AI服务错误: $(grep -c 'ERROR' $LOG_DIR/ai_service.log || echo 0)"
    fi
    
    echo ""
    
    # 请求统计
    echo "📈 请求统计 (今日):"
    today=$(date +%Y-%m-%d)
    
    if [ -f "$LOG_DIR/zhixue.log" ]; then
        backend_requests=$(grep "$today" $LOG_DIR/zhixue.log | grep -c "请求处理" || echo 0)
        echo "  后端API请求: $backend_requests"
    fi
    
    if [ -f "$LOG_DIR/ai_service.log" ]; then
        ai_requests=$(grep "$today" $LOG_DIR/ai_service.log | grep -c "AI请求" || echo 0)
        echo "  AI服务请求: $ai_requests"
    fi
    
    echo ""
    
    # 日志文件大小
    echo "📁 日志文件大小:"
    ls -lh $LOG_DIR/*.log 2>/dev/null | awk '{print "  " $9 ": " $5}'
}

# 主程序
case $1 in
    "tail")
        service=${2:-"all"}
        tail_logs $service
        ;;
    "view")
        service=${2:-"all"}
        lines=${3:-100}
        view_logs $service $lines
        ;;
    "clean")
        clean_logs
        ;;
    "analyze")
        analyze_logs
        ;;
    "help"|"")
        show_help
        ;;
    *)
        echo "❌ 未知命令: $1"
        echo "使用 '$0 help' 查看帮助"
        ;;
esac
