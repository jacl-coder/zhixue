-- ============================================
-- 智学奇境数学学习平台 PostgreSQL 数据库初始化脚本
-- EduVerse AI - Intelligent Learning Database
-- 创建时间: 2025-06-20
-- 版本: v1.0 (PostgreSQL 兼容版本)
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
CREATE TYPE achievement_category AS ENUM ('learning', 'streak', 'difficulty', 'speed', 'special');
CREATE TYPE achievement_rarity AS ENUM ('common', 'uncommon', 'rare', 'epic', 'legendary');
CREATE TYPE leaderboard_type AS ENUM ('daily', 'weekly', 'monthly', 'all_time');
CREATE TYPE metric_type AS ENUM ('score', 'streak', 'questions_solved', 'study_time');
CREATE TYPE config_type AS ENUM ('string', 'integer', 'decimal', 'boolean', 'json');

-- ============================================
-- 1. 用户系统表
-- ============================================

-- 用户基础信息表
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nickname VARCHAR(50) NOT NULL,
    avatar_url VARCHAR(255) DEFAULT '',
    grade_level INTEGER DEFAULT 1 CHECK (grade_level BETWEEN 1 AND 12),
    birth_date DATE,
    gender user_gender DEFAULT 'other',
    status user_status DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE
);

-- 创建索引
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_grade_level ON users(grade_level);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created_at ON users(created_at);

-- 用户学习档案表
CREATE TABLE user_profiles (
    id BIGSERIAL PRIMARY KEY,
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

-- 创建索引
CREATE INDEX idx_user_profiles_difficulty ON user_profiles(current_difficulty);
CREATE INDEX idx_user_profiles_level ON user_profiles(user_level);

-- ============================================
-- 2. 数学题库系统表
-- ============================================

-- 知识点分类表
CREATE TABLE knowledge_points (
    id BIGSERIAL PRIMARY KEY,
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

-- 创建索引
CREATE INDEX idx_knowledge_points_code ON knowledge_points(code);
CREATE INDEX idx_knowledge_points_parent ON knowledge_points(parent_id);
CREATE INDEX idx_knowledge_points_grade ON knowledge_points(grade_level);
CREATE INDEX idx_knowledge_points_active ON knowledge_points(is_active);

-- 数学题目表
CREATE TABLE questions (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    question_type question_type DEFAULT 'single_choice',
    difficulty DECIMAL(3,2) NOT NULL CHECK (difficulty BETWEEN 1.0 AND 5.0),
    grade_level INTEGER NOT NULL CHECK (grade_level BETWEEN 1 AND 12),
    knowledge_point_id BIGINT NOT NULL REFERENCES knowledge_points(id),
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

-- 创建索引和全文搜索
CREATE INDEX idx_questions_difficulty ON questions(difficulty);
CREATE INDEX idx_questions_grade ON questions(grade_level);
CREATE INDEX idx_questions_knowledge_point ON questions(knowledge_point_id);
CREATE INDEX idx_questions_type ON questions(question_type);
CREATE INDEX idx_questions_status ON questions(review_status);
CREATE INDEX idx_questions_active ON questions(is_active);
CREATE INDEX idx_questions_correct_rate ON questions(correct_rate);

-- 全文搜索索引
CREATE INDEX idx_questions_search ON questions USING gin(to_tsvector('chinese', title || ' ' || content));

-- ============================================
-- 3. 学习行为记录表
-- ============================================

-- 答题记录表
CREATE TABLE answer_records (
    id BIGSERIAL PRIMARY KEY,
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX idx_answer_records_user_question ON answer_records(user_id, question_id);
CREATE INDEX idx_answer_records_session ON answer_records(session_id);
CREATE INDEX idx_answer_records_correct ON answer_records(is_correct);
CREATE INDEX idx_answer_records_created_at ON answer_records(created_at);
CREATE INDEX idx_answer_records_user_time ON answer_records(user_id, created_at);

-- 学习会话表
CREATE TABLE learning_sessions (
    id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(64) UNIQUE NOT NULL,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER DEFAULT 0,
    questions_count INTEGER DEFAULT 0,
    correct_count INTEGER DEFAULT 0,
    avg_difficulty DECIMAL(3,2) DEFAULT 0.00,
    session_type session_type DEFAULT 'practice',
    completion_status completion_status DEFAULT 'ongoing',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX idx_learning_sessions_session_id ON learning_sessions(session_id);
CREATE INDEX idx_learning_sessions_user_time ON learning_sessions(user_id, start_time);
CREATE INDEX idx_learning_sessions_status ON learning_sessions(completion_status);

-- ============================================
-- 4. AI系统相关表
-- ============================================

-- AI模型记录表
CREATE TABLE ai_model_records (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    model_type model_type NOT NULL,
    input_features JSONB NOT NULL,
    model_output JSONB NOT NULL,
    confidence_score DECIMAL(5,4) NOT NULL,
    processing_time_ms INTEGER NOT NULL,
    model_version VARCHAR(20) DEFAULT 'v1.0',
    is_successful BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX idx_ai_model_records_user_model ON ai_model_records(user_id, model_type);
CREATE INDEX idx_ai_model_records_created_at ON ai_model_records(created_at);
CREATE INDEX idx_ai_model_records_confidence ON ai_model_records(confidence_score);

-- 难度调节记录表
CREATE TABLE difficulty_adjustments (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    old_difficulty DECIMAL(3,2) NOT NULL,
    new_difficulty DECIMAL(3,2) NOT NULL,
    adjustment_reason TEXT NOT NULL,
    confidence DECIMAL(3,2) NOT NULL,
    trigger_event trigger_event NOT NULL,
    performance_window JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX idx_difficulty_adjustments_user_time ON difficulty_adjustments(user_id, created_at);
CREATE INDEX idx_difficulty_adjustments_trigger ON difficulty_adjustments(trigger_event);

-- ============================================
-- 5. 游戏化系统表
-- ============================================

-- 成就系统表
CREATE TABLE achievements (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    icon_url VARCHAR(255),
    category achievement_category DEFAULT 'learning',
    points INTEGER DEFAULT 0,
    rarity achievement_rarity DEFAULT 'common',
    unlock_condition JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX idx_achievements_code ON achievements(code);
CREATE INDEX idx_achievements_category ON achievements(category);
CREATE INDEX idx_achievements_rarity ON achievements(rarity);

-- 用户成就记录表
CREATE TABLE user_achievements (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id BIGINT NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    progress_data JSONB,
    UNIQUE(user_id, achievement_id)
);

-- 创建索引
CREATE INDEX idx_user_achievements_unlocked_at ON user_achievements(unlocked_at);

-- 排行榜表
CREATE TABLE leaderboards (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    leaderboard_type leaderboard_type NOT NULL,
    metric_type metric_type NOT NULL,
    metric_value INTEGER NOT NULL,
    rank_position INTEGER NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, leaderboard_type, metric_type, period_start)
);

-- 创建索引
CREATE INDEX idx_leaderboards_rank ON leaderboards(leaderboard_type, metric_type, rank_position);
CREATE INDEX idx_leaderboards_period ON leaderboards(period_start, period_end);

-- ============================================
-- 6. 系统配置表
-- ============================================

-- 系统配置表
CREATE TABLE system_configs (
    id BIGSERIAL PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    config_type config_type DEFAULT 'string',
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX idx_system_configs_key ON system_configs(config_key);
CREATE INDEX idx_system_configs_active ON system_configs(is_active);

-- ============================================
-- 7. 初始化基础数据
-- ============================================

-- 插入知识点分类数据
INSERT INTO knowledge_points (name, code, parent_id, grade_level, description, sort_order) VALUES
-- 小学数学 (1-6年级)
('数与运算', 'NUM_CALC', NULL, 1, '数字认知与基础运算', 100),
('图形与几何', 'GEOMETRY', NULL, 1, '平面与立体图形认知', 200),
('统计与概率', 'STATISTICS', NULL, 3, '数据统计与概率初步', 300),
('应用题', 'WORD_PROBLEMS', NULL, 2, '实际生活中的数学应用', 400),

-- 初中数学 (7-9年级)
('代数', 'ALGEBRA', NULL, 7, '代数方程与函数', 500),
('几何证明', 'GEOMETRY_PROOF', NULL, 8, '几何图形的证明与计算', 600),
('三角函数', 'TRIGONOMETRY', NULL, 9, '三角函数基础', 700),

-- 高中数学 (10-12年级)
('函数', 'FUNCTIONS', NULL, 10, '函数性质与应用', 800),
('导数', 'DERIVATIVES', NULL, 11, '导数与微分', 900),
('概率统计', 'PROBABILITY', NULL, 12, '概率论与数理统计', 1000);

-- 插入系统配置数据
INSERT INTO system_configs (config_key, config_value, config_type, description) VALUES
('default_difficulty', '2.5', 'decimal', '新用户默认难度等级'),
('max_hint_count', '3', 'integer', '每题最大提示次数'),
('session_timeout', '30', 'integer', '学习会话超时时间(分钟)'),
('daily_question_limit', '50', 'integer', '每日答题数量限制'),
('difficulty_adjustment_threshold', '0.8', 'decimal', '难度调节触发阈值'),
('ai_model_version', 'v1.0', 'string', '当前AI模型版本'),
('enable_ai_recommendation', 'true', 'boolean', '是否启用AI推荐'),
('leaderboard_update_interval', '60', 'integer', '排行榜更新间隔(分钟)');

-- 插入基础成就数据
INSERT INTO achievements (code, name, description, category, points, rarity, unlock_condition) VALUES
('FIRST_ANSWER', '初出茅庐', '完成第一道题目', 'learning', 10, 'common', '{"type": "answer_count", "value": 1}'),
('STREAK_7', '持之以恒', '连续学习7天', 'streak', 50, 'uncommon', '{"type": "streak_days", "value": 7}'),
('ACCURACY_90', '精准射手', '单次会话正确率达到90%', 'learning', 30, 'uncommon', '{"type": "session_accuracy", "value": 0.9}'),
('SPEED_MASTER', '闪电快手', '平均答题时间少于30秒', 'speed', 40, 'rare', '{"type": "avg_response_time", "value": 30}'),
('DIFFICULTY_5', '挑战极限', '成功答对难度5.0的题目', 'difficulty', 100, 'epic', '{"type": "difficulty_level", "value": 5.0}');

-- ============================================
-- 8. 创建视图
-- ============================================

-- 用户统计视图
CREATE VIEW user_statistics AS
SELECT 
    u.id,
    u.username,
    u.nickname,
    u.grade_level,
    up.current_difficulty,
    up.total_study_time,
    up.total_questions,
    up.correct_answers,
    CASE 
        WHEN up.total_questions > 0 
        THEN ROUND((up.correct_answers::DECIMAL * 100.0 / up.total_questions), 2)
        ELSE 0 
    END as accuracy_rate,
    up.streak_days,
    up.user_level,
    u.last_login_at,
    u.created_at
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
WHERE u.status = 'active';

-- 题目统计视图
CREATE VIEW question_statistics AS
SELECT 
    q.id,
    q.title,
    q.difficulty,
    q.grade_level,
    kp.name as knowledge_point_name,
    q.usage_count,
    q.correct_rate,
    q.avg_response_time,
    COUNT(ar.id) as total_answers,
    SUM(CASE WHEN ar.is_correct THEN 1 ELSE 0 END) as correct_answers
FROM questions q
LEFT JOIN knowledge_points kp ON q.knowledge_point_id = kp.id
LEFT JOIN answer_records ar ON q.id = ar.question_id
WHERE q.is_active = TRUE
GROUP BY q.id, q.title, q.difficulty, q.grade_level, kp.name, q.usage_count, q.correct_rate, q.avg_response_time;

-- ============================================
-- 9. 创建函数
-- ============================================

-- 更新用户学习档案的函数
CREATE OR REPLACE FUNCTION update_user_profile(
    p_user_id BIGINT,
    p_is_correct BOOLEAN,
    p_response_time INTEGER,
    p_difficulty DECIMAL(3,2)
) RETURNS VOID AS $$
BEGIN
    -- 更新或插入用户档案
    INSERT INTO user_profiles (user_id, total_questions, correct_answers, current_difficulty)
    VALUES (p_user_id, 1, CASE WHEN p_is_correct THEN 1 ELSE 0 END, p_difficulty)
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        total_questions = user_profiles.total_questions + 1,
        correct_answers = user_profiles.correct_answers + CASE WHEN p_is_correct THEN 1 ELSE 0 END,
        updated_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- 自动更新 updated_at 的触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
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

CREATE TRIGGER update_leaderboards_updated_at BEFORE UPDATE ON leaderboards 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 10. 性能优化索引
-- ============================================

-- 创建复合索引优化查询性能
CREATE INDEX idx_answer_records_user_date ON answer_records(user_id, DATE(created_at));
CREATE INDEX idx_learning_sessions_user_date ON learning_sessions(user_id, DATE(start_time));

-- ============================================
-- 数据库初始化完成
-- ============================================

SELECT '🎉 智学奇境PostgreSQL数据库初始化完成!' as message;

-- 显示表统计信息
SELECT 
    schemaname,
    COUNT(*) as table_count
FROM pg_tables 
WHERE schemaname = 'public' 
GROUP BY schemaname;

SELECT '🚀 可以开始开发API接口了!' as next_step;
