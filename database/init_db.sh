#!/bin/bash
# 智学奇境数据库初始化脚本

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
    if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
        print_warning "数据库 $DB_NAME 已存在"
    else
        sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH ENCODING 'UTF8';"
        print_status "数据库 $DB_NAME 创建成功"
    fi
    
    # 检查用户是否存在
    if sudo -u postgres psql -c "\du" | grep -qw $DB_USER; then
        print_warning "用户 $DB_USER 已存在"
    else
        sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
        print_status "用户 $DB_USER 创建成功"
    fi
    
    # 授权
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
    sudo -u postgres psql -c "ALTER USER $DB_USER CREATEDB;"
    print_status "权限授予完成"
}

# 初始化数据库表结构
function init_database_schema() {
    print_info "初始化数据库表结构..."
    
    if [ -f "./database/init_postgresql.sql" ]; then
        # 使用创建的用户连接数据库
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f ./database/init_postgresql.sql
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

# 创建测试数据
function create_test_data() {
    print_info "创建测试数据..."
    
    # 创建测试数据的SQL
    cat > /tmp/test_data.sql << 'EOF'
-- 创建测试用户
INSERT INTO users (username, email, password_hash, nickname, grade_level) VALUES
('test_student1', 'student1@zhixue.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iKWl5rl8.Cy8sKNXlQGJLBP.7FG6', '小明', 5),
('test_student2', 'student2@zhixue.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iKWl5rl8.Cy8sKNXlQGJLBP.7FG6', '小红', 6),
('test_teacher', 'teacher@zhixue.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iKWl5rl8.Cy8sKNXlQGJLBP.7FG6', '王老师', 12);

-- 创建测试题目
INSERT INTO questions (title, content, question_type, difficulty, grade_level, knowledge_point_id, correct_answer, choices) VALUES
('简单加法', '计算: 3 + 5 = ?', 'single_choice', 1.0, 1, 1, '8', '["6", "7", "8", "9"]'),
('分数计算', '计算: 1/2 + 1/3 = ?', 'single_choice', 2.5, 5, 1, '5/6', '["2/5", "5/6", "2/3", "3/4"]'),
('代数方程', '解方程: 2x + 3 = 11', 'fill_blank', 3.0, 7, 5, '4', NULL),
('几何面积', '正方形边长为5cm，求面积', 'calculation', 2.0, 4, 2, '25', NULL),
('函数极值', '求函数 f(x) = x² - 4x + 3 的最小值', 'calculation', 4.5, 11, 8, '-1', NULL);

-- 创建用户档案
INSERT INTO user_profiles (user_id, current_difficulty, total_study_time, total_questions, correct_answers) VALUES
(1, 1.5, 120, 25, 20),
(2, 2.0, 200, 40, 32),
(3, 5.0, 500, 100, 95);

-- 创建一些答题记录
INSERT INTO answer_records (user_id, question_id, session_id, user_answer, is_correct, response_time, difficulty_at_time) VALUES
(1, 1, 'session_001', '8', true, 15, 1.0),
(1, 2, 'session_001', '5/6', true, 45, 1.5),
(2, 1, 'session_002', '8', true, 12, 2.0),
(2, 3, 'session_002', '4', true, 60, 2.0);

EOF

    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f /tmp/test_data.sql
    if [ $? -eq 0 ]; then
        print_status "测试数据创建成功"
        rm /tmp/test_data.sql
    else
        print_error "测试数据创建失败"
        return 1
    fi
}

# 验证数据库
function verify_database() {
    print_info "验证数据库安装..."
    
    # 检查表数量
    table_count=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
    print_status "共创建 $table_count 个表"
    
    # 检查用户数量
    user_count=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM users;")
    print_status "共有 $user_count 个测试用户"
    
    # 检查题目数量
    question_count=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM questions;")
    print_status "共有 $question_count 道测试题目"
    
    # 检查知识点数量
    knowledge_count=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM knowledge_points;")
    print_status "共有 $knowledge_count 个知识点"
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
    
    # 创建测试数据
    read -p "是否创建测试数据? (y/N): " create_test
    if [[ $create_test =~ ^[Yy]$ ]]; then
        create_test_data
    fi
    
    # 验证数据库
    verify_database
    
    # 显示连接信息
    show_connection_info
    
    echo ""
    print_status "🎉 智学奇境数据库初始化完成!"
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
    echo "  help     显示帮助信息"
}

# 清理数据库
function clean_database() {
    print_warning "这将删除所有数据库数据，确定要继续吗?"
    read -p "输入 'yes' 确认删除: " confirm
    if [ "$confirm" = "yes" ]; then
        sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;"
        sudo -u postgres psql -c "DROP USER IF EXISTS $DB_USER;"
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
    "help")
        show_help
        ;;
    *)
        echo "未知选项: $1"
        show_help
        exit 1
        ;;
esac
