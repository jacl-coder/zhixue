#!/bin/bash
# 智学奇境数据库初始化脚本

export PGPASSWORD="1024"

echo "🗄️ 智学奇境数据库初始化工具"
echo "================================="

# 数据库配置
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="zhixue_db"
DB_USER="zhixue_user"
DB_PASSWORD="1024"
ADMIN_USER="postgres"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

function print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

function print_error() {
    echo -e "${RED}❌ $1${NC}"
}

function print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 检查PostgreSQL是否运行
function check_postgresql() {
    print_info "检查PostgreSQL服务状态..."
    if sudo systemctl is-active --quiet postgresql; then
        print_status "PostgreSQL服务正在运行"
        return 0
    else
        print_warning "PostgreSQL服务未运行，尝试启动..."
        sudo systemctl start postgresql
        if sudo systemctl is-active --quiet postgresql; then
            print_status "PostgreSQL服务启动成功"
            return 0
        else
            print_error "PostgreSQL服务启动失败"
            return 1
        fi
    fi
}

# 创建数据库和用户
function create_database_user() {
    print_info "创建数据库和用户..."
    
    # 检查数据库是否存在
    if psql -U postgres -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
        print_warning "数据库 $DB_NAME 已存在"
    else
        psql -U postgres -c "CREATE DATABASE $DB_NAME WITH ENCODING 'UTF8';"
        print_status "数据库 $DB_NAME 创建成功"
    fi
    
    # 检查用户是否存在
    if psql -U postgres -c "\du" | grep -qw $DB_USER; then
        print_warning "用户 $DB_USER 已存在"
    else
        psql -U postgres -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
        print_status "用户 $DB_USER 创建成功"
    fi
    
    # 授权
    psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
    psql -U postgres -c "ALTER USER $DB_USER CREATEDB;"
    print_status "权限授予完成"
}

# 初始化数据库表结构
function init_database_schema() {
    print_info "初始化数据库表结构..."
    
    if [ -f "./database/init_postgresql.sql" ]; then
        # 使用创建的用户连接数据库
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f ./database/init_postgresql.sql
        if [ $? -eq 0 ]; then
            print_status "数据库表结构初始化成功"
        else
            print_error "数据库表结构初始化失败"
            return 1
        fi
    else
        print_error "找不到数据库初始化脚本 ./database/init_postgresql.sql"
        return 1
    fi
}

# 验证数据库
function verify_database() {
    print_info "验证数据库安装..."
    
    # 检查表数量
    table_count=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
    print_status "共创建 $table_count 个表"
    
    # 检查用户数量
    user_count=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM users;")
    print_status "共有 $user_count 个用户"
    
    # 检查题目数量
    question_count=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM questions;")
    print_status "共有 $question_count 道题目"
    
    # 检查知识点数量
    knowledge_count=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM knowledge_points;")
    print_status "共有 $knowledge_count 个知识点"
    
    # 检查分区表答题记录数量
    answer_count=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM answer_records;")
    print_status "共有 $answer_count 条答题记录"
}

# 显示连接信息
function show_connection_info() {
    echo ""
    echo "📊 数据库连接信息:"
    echo "================================="
    echo "主机: $DB_HOST:$DB_PORT"
    echo "数据库: $DB_NAME"
    echo "用户: $DB_USER"
    echo "密码: $DB_PASSWORD"
    echo ""
    echo "🔗 连接命令:"
    echo "psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
    echo ""
    echo "🌐 Go连接字符串:"
    echo "postgres://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME?sslmode=disable"
}

# 自动管理 answer_records 分区表（每月创建新分区，清理24个月前分区）
function manage_answer_partitions() {
    print_info "自动管理 answer_records 分区表..."
    # 创建下月分区
    NEXT_MONTH=$(date -d "$(date +%Y-%m-01) +1 month" +%Y_%m)
    START_DATE=$(date -d "$(date +%Y-%m-01) +1 month" +%Y-%m-01)
    END_DATE=$(date -d "$(date +%Y-%m-01) +2 month" +%Y-%m-01)
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "CREATE TABLE IF NOT EXISTS answer_records_${NEXT_MONTH} PARTITION OF answer_records FOR VALUES FROM ('${START_DATE}') TO ('${END_DATE}');"
    # 清理24个月前分区
    OLD_MONTH=$(date -d "$(date +%Y-%m-01) -24 month" +%Y_%m)
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "ALTER TABLE answer_records DETACH PARTITION answer_records_${OLD_MONTH};"
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "DROP TABLE IF EXISTS answer_records_${OLD_MONTH};"
    print_status "answer_records 分区表自动管理完成"
}

# 主函数
function main() {
    echo "开始初始化智学奇境数据库..."
    echo ""
    
    # 检查PostgreSQL
    if ! check_postgresql; then
        exit 1
    fi
    
    # 创建数据库和用户
    if ! create_database_user; then
        exit 1
    fi
    
    # 初始化表结构
    if ! init_database_schema; then
        exit 1
    fi
    
    # 验证数据库
    verify_database
    
    # 显示连接信息
    show_connection_info
    
    echo ""
    print_status "🎉 智学奇境数据库结构初始化完成!"
    print_info "现在可以开始开发后端API了"
}

# 帮助信息
function show_help() {
    echo "智学奇境数据库初始化工具"
    echo ""
    echo "使用方法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  init     初始化数据库 (默认)"
    echo "  verify   验证数据库状态"
    echo "  clean    清理数据库"
    echo "  partition  自动管理 answer_records 分区表（建议配合cron定时执行）"
    echo "  help     显示帮助信息"
}

# 清理数据库
function clean_database() {
    print_warning "这将删除所有数据库数据，确定要继续吗?"
    read -p "输入 'yes' 确认删除: " confirm
    if [ "$confirm" = "yes" ]; then
        psql -U postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
        psql -U postgres -c "DROP USER IF EXISTS $DB_USER;"
        print_status "数据库清理完成"
    else
        print_info "操作已取消"
    fi
}

# 根据参数执行不同操作
case "${1:-init}" in
    "init")
        main
        ;;
    "verify")
        verify_database
        show_connection_info
        ;;
    "clean")
        clean_database
        ;;
    "partition")
        manage_answer_partitions
        ;;
    "help")
        show_help
        ;;
    *)
        echo "未知选项: $1"
        show_help
        exit 1
        ;;
esac
