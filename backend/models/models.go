/*
File: models.go
Author: lxp
Description: 数据模型定义 (GORM模型)
*/
package models

import (
	"database/sql/driver"
	"encoding/json"
	"time"

	"gorm.io/gorm"
)

// JSONB 自定义类型，用于PostgreSQL JSONB字段
type JSONB map[string]interface{}

func (j JSONB) Value() (driver.Value, error) {
	return json.Marshal(j)
}

func (j *JSONB) Scan(value interface{}) error {
	bytes, ok := value.([]byte)
	if !ok {
		return nil
	}
	return json.Unmarshal(bytes, j)
}

// User 用户基础信息模型
type User struct {
	ID           uint64     `json:"id" gorm:"primaryKey;autoIncrement"`
	Username     string     `json:"username" gorm:"uniqueIndex;size:50;not null"`
	Email        string     `json:"email" gorm:"uniqueIndex;size:100;not null"`
	PasswordHash string     `json:"-" gorm:"size:255;not null"` // 不返回密码
	Nickname     string     `json:"nickname" gorm:"size:50"`
	AvatarURL    string     `json:"avatar_url" gorm:"size:500"`
	Grade        int        `json:"grade" gorm:"default:6"`               // 年级 1-12
	Role         string     `json:"role" gorm:"size:20;default:student"`  // student/teacher/admin
	Status       string     `json:"status" gorm:"size:20;default:active"` // active/inactive/banned
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
	LastLoginAt  *time.Time `json:"last_login_at"`

	// 关联关系
	Profile      *UserProfile      `json:"profile,omitempty"`
	Analytics    []UserAnalytics   `json:"analytics,omitempty"`
	Achievements []UserAchievement `json:"achievements,omitempty"`
}

// UserProfile 用户详细信息模型
type UserProfile struct {
	UserID       uint64    `json:"user_id" gorm:"primaryKey"`
	RealName     string    `json:"real_name" gorm:"size:50"`
	Phone        string    `json:"phone" gorm:"size:20"`
	School       string    `json:"school" gorm:"size:100"`
	ClassName    string    `json:"class_name" gorm:"size:50"`
	ParentPhone  string    `json:"parent_phone" gorm:"size:20"`
	LearningGoal string    `json:"learning_goal" gorm:"type:text"`
	Timezone     string    `json:"timezone" gorm:"size:50;default:Asia/Shanghai"`
	Language     string    `json:"language" gorm:"size:10;default:zh-CN"`
	Preferences  JSONB     `json:"preferences" gorm:"type:jsonb"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`

	// 外键关联
	User User `json:"user" gorm:"foreignKey:UserID"`
}

// KnowledgePoint 知识点模型
type KnowledgePoint struct {
	ID              uint64    `json:"id" gorm:"primaryKey;autoIncrement"`
	Name            string    `json:"name" gorm:"size:100;not null"`
	Description     string    `json:"description" gorm:"type:text"`
	Grade           int       `json:"grade" gorm:"not null;index:idx_grade_subject"`
	Subject         string    `json:"subject" gorm:"size:50;default:math;index:idx_grade_subject"`
	ParentID        *uint64   `json:"parent_id" gorm:"index"`
	DifficultyLevel int       `json:"difficulty_level" gorm:"default:1;index"`
	OrderIndex      int       `json:"order_index" gorm:"default:0"`
	Status          string    `json:"status" gorm:"size:20;default:active"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`

	// 关联关系
	Parent    *KnowledgePoint  `json:"parent,omitempty" gorm:"foreignKey:ParentID"`
	Children  []KnowledgePoint `json:"children,omitempty" gorm:"foreignKey:ParentID"`
	Questions []Question       `json:"questions,omitempty"`
}

// Question 题目模型
type Question struct {
	ID               uint64    `json:"id" gorm:"primaryKey;autoIncrement"`
	Title            string    `json:"title" gorm:"size:500;not null"`
	Content          string    `json:"content" gorm:"type:text;not null"`
	QuestionType     string    `json:"question_type" gorm:"size:50;not null;index:idx_type_status"`
	Difficulty       float64   `json:"difficulty" gorm:"type:decimal(3,2);default:1.0;index"`
	KnowledgePointID uint64    `json:"knowledge_point_id" gorm:"index"`
	Options          JSONB     `json:"options" gorm:"type:jsonb"`
	CorrectAnswer    JSONB     `json:"correct_answer" gorm:"type:jsonb;not null"`
	Explanation      string    `json:"explanation" gorm:"type:text"`
	Hints            JSONB     `json:"hints" gorm:"type:jsonb"`
	Tags             []string  `json:"tags" gorm:"type:text[]"`
	EstimatedTime    int       `json:"estimated_time" gorm:"default:60"` // 秒
	AuthorID         uint64    `json:"author_id"`
	Status           string    `json:"status" gorm:"size:20;default:active;index:idx_type_status"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`

	// 关联关系
	KnowledgePoint KnowledgePoint `json:"knowledge_point" gorm:"foreignKey:KnowledgePointID"`
	Author         User           `json:"author" gorm:"foreignKey:AuthorID"`
}

// UserAnswerRecord 用户答题记录模型
type UserAnswerRecord struct {
	ID               uint64    `json:"id" gorm:"primaryKey;autoIncrement"`
	UserID           uint64    `json:"user_id" gorm:"not null;index:idx_user_time"`
	QuestionID       uint64    `json:"question_id" gorm:"not null;index"`
	SessionID        string    `json:"session_id" gorm:"size:100;index"`
	UserAnswer       JSONB     `json:"user_answer" gorm:"type:jsonb"`
	IsCorrect        bool      `json:"is_correct" gorm:"not null;index:idx_correct_time"`
	ResponseTime     int       `json:"response_time"` // 秒
	AttemptCount     int       `json:"attempt_count" gorm:"default:1"`
	HintUsed         bool      `json:"hint_used" gorm:"default:false"`
	DifficultyAtTime float64   `json:"difficulty_at_time" gorm:"type:decimal(3,2)"`
	AIConfidence     float64   `json:"ai_confidence" gorm:"type:decimal(4,3)"`
	CreatedAt        time.Time `json:"created_at" gorm:"index:idx_user_time,idx_correct_time"`

	// 关联关系
	User     User     `json:"user" gorm:"foreignKey:UserID"`
	Question Question `json:"question" gorm:"foreignKey:QuestionID"`
}

// LearningSession 学习会话模型
type LearningSession struct {
	ID               string     `json:"id" gorm:"primaryKey;size:100"` // UUID
	UserID           uint64     `json:"user_id" gorm:"not null;index:idx_user_time"`
	SessionType      string     `json:"session_type" gorm:"size:50;default:practice"`
	KnowledgePointID *uint64    `json:"knowledge_point_id"`
	StartTime        time.Time  `json:"start_time" gorm:"default:CURRENT_TIMESTAMP;index:idx_user_time"`
	EndTime          *time.Time `json:"end_time"`
	TotalQuestions   int        `json:"total_questions" gorm:"default:0"`
	CorrectQuestions int        `json:"correct_questions" gorm:"default:0"`
	TotalTime        int        `json:"total_time"` // 秒
	AvgResponseTime  float64    `json:"avg_response_time" gorm:"type:decimal(6,2)"`
	DifficultyStart  float64    `json:"difficulty_start" gorm:"type:decimal(3,2)"`
	DifficultyEnd    float64    `json:"difficulty_end" gorm:"type:decimal(3,2)"`
	AIAdjustments    int        `json:"ai_adjustments" gorm:"default:0"`
	Status           string     `json:"status" gorm:"size:20;default:active;index"`
	CreatedAt        time.Time  `json:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at"`

	// 关联关系
	User           User               `json:"user" gorm:"foreignKey:UserID"`
	KnowledgePoint *KnowledgePoint    `json:"knowledge_point,omitempty" gorm:"foreignKey:KnowledgePointID"`
	AnswerRecords  []UserAnswerRecord `json:"answer_records,omitempty" gorm:"foreignKey:SessionID;references:ID"`
}

// UserAnalytics 用户学习分析模型
type UserAnalytics struct {
	ID                   uint64     `json:"id" gorm:"primaryKey;autoIncrement"`
	UserID               uint64     `json:"user_id" gorm:"not null;uniqueIndex:idx_user_knowledge"`
	KnowledgePointID     *uint64    `json:"knowledge_point_id" gorm:"uniqueIndex:idx_user_knowledge"`
	MasteryLevel         float64    `json:"mastery_level" gorm:"type:decimal(4,3);default:0.0;index"`
	DifficultyPreference float64    `json:"difficulty_preference" gorm:"type:decimal(3,2);default:2.5"`
	LearningSpeed        float64    `json:"learning_speed" gorm:"type:decimal(4,2)"` // 题/分钟
	AccuracyRate         float64    `json:"accuracy_rate" gorm:"type:decimal(4,3)"`
	TotalPracticeTime    int        `json:"total_practice_time" gorm:"default:0"` // 秒
	LastPracticeAt       *time.Time `json:"last_practice_at"`
	StrengthScore        float64    `json:"strength_score" gorm:"type:decimal(4,3)"`
	WeaknessScore        float64    `json:"weakness_score" gorm:"type:decimal(4,3)"`
	AIRecommendation     JSONB      `json:"ai_recommendation" gorm:"type:jsonb"`
	UpdatedAt            time.Time  `json:"updated_at"`

	// 关联关系
	User           User            `json:"user" gorm:"foreignKey:UserID"`
	KnowledgePoint *KnowledgePoint `json:"knowledge_point,omitempty" gorm:"foreignKey:KnowledgePointID"`
}

// UserAchievement 用户成就模型
type UserAchievement struct {
	ID              uint64    `json:"id" gorm:"primaryKey;autoIncrement"`
	UserID          uint64    `json:"user_id" gorm:"not null;index"`
	AchievementType string    `json:"achievement_type" gorm:"size:50;not null;index"`
	AchievementName string    `json:"achievement_name" gorm:"size:100;not null"`
	Description     string    `json:"description" gorm:"type:text"`
	Points          int       `json:"points" gorm:"default:0"`
	BadgeIcon       string    `json:"badge_icon" gorm:"size:200"`
	UnlockedAt      time.Time `json:"unlocked_at" gorm:"default:CURRENT_TIMESTAMP"`
	Level           int       `json:"level" gorm:"default:1"`

	// 关联关系
	User User `json:"user" gorm:"foreignKey:UserID"`
}

// GameRoom 游戏房间模型
type GameRoom struct {
	ID               string     `json:"id" gorm:"primaryKey;size:100"` // UUID
	RoomName         string     `json:"room_name" gorm:"size:100"`
	RoomType         string     `json:"room_type" gorm:"size:50;default:practice"`
	MaxPlayers       int        `json:"max_players" gorm:"default:4"`
	CurrentPlayers   int        `json:"current_players" gorm:"default:0"`
	KnowledgePointID *uint64    `json:"knowledge_point_id" gorm:"index"`
	DifficultyLevel  float64    `json:"difficulty_level" gorm:"type:decimal(3,2);default:2.5"`
	Status           string     `json:"status" gorm:"size:20;default:waiting;index"`
	CreatedBy        uint64     `json:"created_by"`
	CreatedAt        time.Time  `json:"created_at"`
	StartedAt        *time.Time `json:"started_at"`
	EndedAt          *time.Time `json:"ended_at"`

	// 关联关系
	KnowledgePoint *KnowledgePoint `json:"knowledge_point,omitempty" gorm:"foreignKey:KnowledgePointID"`
	Creator        User            `json:"creator" gorm:"foreignKey:CreatedBy"`
}

// TableName 方法用于指定表名
func (User) TableName() string             { return "users" }
func (UserProfile) TableName() string      { return "user_profiles" }
func (KnowledgePoint) TableName() string   { return "knowledge_points" }
func (Question) TableName() string         { return "questions" }
func (UserAnswerRecord) TableName() string { return "user_answer_records" }
func (LearningSession) TableName() string  { return "learning_sessions" }
func (UserAnalytics) TableName() string    { return "user_learning_analytics" }
func (UserAchievement) TableName() string  { return "user_achievements" }
func (GameRoom) TableName() string         { return "game_rooms" }

// 模型验证方法
func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.CreatedAt.IsZero() {
		u.CreatedAt = time.Now()
	}
	if u.UpdatedAt.IsZero() {
		u.UpdatedAt = time.Now()
	}
	return nil
}

func (u *User) BeforeUpdate(tx *gorm.DB) error {
	u.UpdatedAt = time.Now()
	return nil
}
