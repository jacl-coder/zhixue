-- ============================================
-- 智学奇境数学学习平台 PostgreSQL 数据库初始化脚本（MVP精简版）
-- 仅保留MVP核心功能相关表结构
-- ============================================

-- 创建数据库和用户 (在PostgreSQL中单独执行)
-- CREATE DATABASE zhixue_db WITH ENCODING 'UTF8';
-- CREATE USER zhixue_user WITH PASSWORD '1024';
-- GRANT ALL PRIVILEGES ON DATABASE zhixue_db TO zhixue_user;

-- 连接到数据库
\c zhixue_db;

-- 设置时区
SET TIME ZONE 'Asia/Shanghai';

-- 创建枚举类型
CREATE TYPE user_gender AS ENUM ('male', 'female', 'other');
CREATE TYPE user_status AS ENUM ('active', 'inactive', 'banned');
CREATE TYPE learning_style AS ENUM ('visual', 'auditory', 'kinesthetic', 'mixed');
CREATE TYPE question_type AS ENUM ('single_choice', 'multiple_choice', 'fill_blank', 'calculation', 'proof');
CREATE TYPE review_status AS ENUM ('draft', 'reviewing', 'approved', 'rejected');
CREATE TYPE answer_method AS ENUM ('direct', 'hint', 'guess');
CREATE TYPE session_type AS ENUM ('practice', 'test', 'challenge');
CREATE TYPE completion_status AS ENUM ('ongoing', 'completed', 'interrupted');
CREATE TYPE model_type AS ENUM ('difficulty_adjustment', 'recommendation', 'performance_prediction');
CREATE TYPE trigger_event AS ENUM ('answer_correct', 'answer_wrong', 'time_based', 'manual');
CREATE TYPE config_type AS ENUM ('string', 'integer', 'decimal', 'boolean', 'json');
CREATE TYPE user_role AS ENUM ('user', 'admin', 'teacher');
CREATE TYPE task_type AS ENUM ('daily', 'weekly', 'achievement');
CREATE TYPE task_status AS ENUM ('pending', 'completed', 'claimed');
CREATE TYPE reward_type AS ENUM ('points', 'item', 'badge');

-- ============================================
-- 1. 用户系统表
-- ============================================

-- 建议：新项目可用 GENERATED ALWAYS AS IDENTITY 替代 BIGSERIAL，示例：
-- id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nickname VARCHAR(50) NOT NULL,
    avatar_url VARCHAR(255) DEFAULT '',
    grade_level INTEGER DEFAULT 1 CHECK (grade_level BETWEEN 1 AND 12),
    birth_date DATE,
    gender user_gender DEFAULT 'other',
    status user_status DEFAULT 'active',
    role user_role NOT NULL DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE
);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_grade_level ON users(grade_level);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_role ON users(role);

CREATE TABLE user_profiles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    current_difficulty DECIMAL(3,2) DEFAULT 1.0 CHECK (current_difficulty BETWEEN 1.0 AND 5.0),
    total_study_time INTEGER DEFAULT 0,
    total_questions INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    streak_days INTEGER DEFAULT 0,
    max_streak_days INTEGER DEFAULT 0,
    level_score INTEGER DEFAULT 0,
    user_level INTEGER DEFAULT 1,
    learning_style learning_style DEFAULT 'mixed',
    preferred_difficulty DECIMAL(3,2) DEFAULT 2.5,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);
CREATE INDEX idx_user_profiles_difficulty ON user_profiles(current_difficulty);
CREATE INDEX idx_user_profiles_level ON user_profiles(user_level);

CREATE TABLE user_grade_history (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    grade_level INTEGER NOT NULL CHECK (grade_level BETWEEN 1 AND 12),
    start_date DATE NOT NULL,
    end_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, grade_level)
);
CREATE INDEX idx_user_grade_history_user_id ON user_grade_history(user_id);

-- ============================================
-- 2. 数学题库系统表
-- ============================================

CREATE TABLE knowledge_points (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    parent_id BIGINT REFERENCES knowledge_points(id) ON DELETE SET NULL,
    grade_level INTEGER NOT NULL CHECK (grade_level BETWEEN 1 AND 12),
    difficulty_range VARCHAR(10) DEFAULT '1.0-5.0',
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_knowledge_points_code ON knowledge_points(code);
CREATE INDEX idx_knowledge_points_parent ON knowledge_points(parent_id);
CREATE INDEX idx_knowledge_points_grade ON knowledge_points(grade_level);
CREATE INDEX idx_knowledge_points_active ON knowledge_points(is_active);

CREATE TABLE questions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    question_type question_type DEFAULT 'single_choice',
    difficulty DECIMAL(3,2) NOT NULL CHECK (difficulty BETWEEN 1.0 AND 5.0),
    grade_level INTEGER NOT NULL CHECK (grade_level BETWEEN 1 AND 12),
    estimated_time INTEGER DEFAULT 60,
    correct_answer TEXT NOT NULL,
    answer_analysis TEXT,
    hints JSONB,
    choices JSONB,
    tags JSONB,
    source VARCHAR(100) DEFAULT '',
    author_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    review_status review_status DEFAULT 'draft',
    usage_count INTEGER DEFAULT 0,
    correct_rate DECIMAL(5,2) DEFAULT 0.00,
    avg_response_time INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);
CREATE INDEX idx_questions_grade ON questions(grade_level);
CREATE INDEX idx_questions_type ON questions(question_type);
CREATE INDEX idx_questions_status ON questions(review_status);
CREATE INDEX idx_questions_active ON questions(is_active);
CREATE INDEX idx_questions_correct_rate ON questions(correct_rate);
CREATE INDEX idx_questions_search ON questions USING gin(to_tsvector('simple', title || ' ' || content));

CREATE TABLE question_knowledge_points (
    question_id BIGINT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    knowledge_point_id BIGINT NOT NULL REFERENCES knowledge_points(id) ON DELETE CASCADE,
    PRIMARY KEY (question_id, knowledge_point_id)
);
CREATE INDEX idx_qkp_question_id ON question_knowledge_points(question_id);
CREATE INDEX idx_qkp_knowledge_point_id ON question_knowledge_points(knowledge_point_id);

-- ============================================
-- 3. 学习行为记录表
-- ============================================

CREATE TABLE answer_records (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_id BIGINT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    session_id VARCHAR(64),
    user_answer TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL,
    response_time INTEGER NOT NULL,
    hint_used_count INTEGER DEFAULT 0,
    difficulty_at_time DECIMAL(3,2) NOT NULL,
    confidence_score DECIMAL(3,2),
    answer_method answer_method DEFAULT 'direct',
    ip_address INET,
    device_info JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);
CREATE INDEX idx_answer_records_user_question ON answer_records(user_id, question_id);
CREATE INDEX idx_answer_records_session ON answer_records(session_id);
CREATE INDEX idx_answer_records_correct ON answer_records(is_correct);
CREATE INDEX idx_answer_records_created_at ON answer_records(created_at);
CREATE INDEX idx_answer_records_user_time ON answer_records(user_id, created_at);
CREATE TABLE answer_records_default PARTITION OF answer_records DEFAULT;

CREATE TABLE learning_sessions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    session_id VARCHAR(64) UNIQUE NOT NULL,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    questions_count INTEGER DEFAULT 0,
    correct_count INTEGER DEFAULT 0,
    avg_difficulty DECIMAL(3,2) DEFAULT 0.00,
    session_type session_type DEFAULT 'practice',
    completion_status completion_status DEFAULT 'ongoing',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_learning_sessions_session_id ON learning_sessions(session_id);
CREATE INDEX idx_learning_sessions_user_time ON learning_sessions(user_id, start_time);
CREATE INDEX idx_learning_sessions_status ON learning_sessions(completion_status);

-- ============================================
-- 4. AI系统相关表（MVP仅保留难度调节相关）
-- ============================================

CREATE TABLE difficulty_adjustments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    old_difficulty DECIMAL(3,2) NOT NULL,
    new_difficulty DECIMAL(3,2) NOT NULL,
    adjustment_reason TEXT NOT NULL,
    confidence DECIMAL(3,2) NOT NULL,
    trigger_event trigger_event NOT NULL,
    performance_window JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_difficulty_adjustments_user_time ON difficulty_adjustments(user_id, created_at);
CREATE INDEX idx_difficulty_adjustments_trigger ON difficulty_adjustments(trigger_event);

-- ============================================
-- 5. 系统配置表（可选）
-- ============================================

CREATE TABLE system_configs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    config_type config_type DEFAULT 'string',
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_system_configs_key ON system_configs(config_key);
CREATE INDEX idx_system_configs_active ON system_configs(is_active);

-- ============================================
-- 6. 游戏化任务与奖励系统表（MVP必需）
-- ============================================

CREATE TABLE rewards (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    reward_type reward_type DEFAULT 'points',
    value INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tasks (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    type task_type NOT NULL DEFAULT 'daily',
    reward_id BIGINT REFERENCES rewards(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_tasks (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    status task_status NOT NULL DEFAULT 'pending',
    progress INTEGER DEFAULT 0,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, task_id)
);

CREATE TABLE user_rewards (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reward_id BIGINT NOT NULL REFERENCES rewards(id) ON DELETE CASCADE,
    obtained_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 为游戏化系统表添加必要的索引（MVP必需）
CREATE INDEX idx_tasks_reward_id ON tasks(reward_id);
CREATE INDEX idx_user_tasks_user_id ON user_tasks(user_id);
CREATE INDEX idx_user_tasks_task_id ON user_tasks(task_id);
CREATE INDEX idx_user_rewards_user_id ON user_rewards(user_id);
CREATE INDEX idx_user_rewards_reward_id ON user_rewards(reward_id);

-- ============================================
-- 触发器与函数（自动更新时间戳）
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_knowledge_points_updated_at BEFORE UPDATE ON knowledge_points 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_questions_updated_at BEFORE UPDATE ON questions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_learning_sessions_updated_at BEFORE UPDATE ON learning_sessions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_system_configs_updated_at BEFORE UPDATE ON system_configs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 种子数据插入SQL（首次部署时可直接执行）
-- ============================================
INSERT INTO knowledge_points (name, code, grade_level, description) VALUES ('加法', 'MATH_ADD', 1, '一年级加法基础');
INSERT INTO system_configs (config_key, config_value, description) VALUES ('default_avatar', 'default.png', '默认头像');
INSERT INTO rewards (name, reward_type, value) VALUES ('新手奖励', 'points', 100);
INSERT INTO tasks (name, description, reward_id) VALUES ('每日答题', '每天完成5道题目', 1);
INSERT INTO users (username, email, password_hash, nickname, role) VALUES ('admin', 'admin@example.com', 'HASHED_PASSWORD', '管理员', 'admin');

-- ============================================
-- 数据库初始化完成（MVP版）
-- ============================================

SELECT '🎉 智学奇境PostgreSQL数据库初始化（MVP）完成!' as message;

-- 显示表统计信息
SELECT 
    schemaname,
    COUNT(*) as table_count
FROM pg_tables 
WHERE schemaname = 'public' 
GROUP BY schemaname;

SELECT '🚀 可以开始开发API接口了!' as next_step;

-- JSONB字段性能提示：如数据量大、字段内容大，建议将高频查询字段提升为独立列并加索引，避免TOAST性能瓶颈。
-- ENUM低基数索引：如仅需查询特殊状态，建议用Partial Index，如：
-- CREATE INDEX idx_users_banned ON users(id) WHERE status = 'banned';

-- answer_records分区表维护建议：需定期自动创建新分区、清理旧分区，可用定时任务实现。

-- ============================================
-- 附录：MVP上线与运维关键建议与脚本模板
-- ============================================

-- 1. 实时排行榜（Redis同步）
-- 建议：当 user_profiles.level_score 发生变动时，后端服务需同步更新 Redis ZSET 排行榜。
-- 伪代码示例：
-- redis.zadd('level_score_rank', new_score, user_id)
-- 查询排行榜时直接用 Redis ZSET 获取前N名，避免数据库高负载。

-- 2. answer_records 分区表自动化管理 SQL 脚本模板
-- 可用于定时任务（cron），每月自动创建新分区、清理旧分区（例子）
-- 0 1 1 * * /root/zhixue/database/init_db.sh partition >> /root/zhixue/database/partition_cron.log 2>&1

-- 以上内容为MVP上线和运维的关键补充，建议结合实际业务完善和自动化。
