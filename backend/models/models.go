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
)

// JSONB类型
// 用于PostgreSQL JSONB字段
// 用法：gorm:"type:jsonb"
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

// ================= 用户系统 =================
type User struct {
	ID           int64  `gorm:"primaryKey;autoIncrement"`
	Username     string `gorm:"size:50;uniqueIndex;not null"`
	Email        string `gorm:"size:100;uniqueIndex;not null"`
	PasswordHash string `gorm:"size:255;not null"`
	Nickname     string `gorm:"size:50;not null"`
	AvatarURL    string `gorm:"size:255;default:''"`
	GradeLevel   int    `gorm:"default:1"`
	BirthDate    *time.Time
	Gender       string    `gorm:"type:user_gender;default:'other'"`
	Status       string    `gorm:"type:user_status;default:'active'"`
	Role         string    `gorm:"type:user_role;default:'user'"`
	CreatedAt    time.Time `gorm:"autoCreateTime"`
	UpdatedAt    time.Time `gorm:"autoUpdateTime"`
	LastLoginAt  *time.Time
	Profiles     []UserProfile `gorm:"foreignKey:UserID"`
}

type UserProfile struct {
	ID                  int64     `gorm:"primaryKey;autoIncrement"`
	UserID              int64     `gorm:"not null;uniqueIndex"`
	CurrentDifficulty   float64   `gorm:"type:decimal(3,2);default:1.0"`
	TotalStudyTime      int       `gorm:"default:0"`
	TotalQuestions      int       `gorm:"default:0"`
	CorrectAnswers      int       `gorm:"default:0"`
	StreakDays          int       `gorm:"default:0"`
	MaxStreakDays       int       `gorm:"default:0"`
	LevelScore          int       `gorm:"default:0"`
	UserLevel           int       `gorm:"default:1"`
	LearningStyle       string    `gorm:"type:learning_style;default:'mixed'"`
	PreferredDifficulty float64   `gorm:"type:decimal(3,2);default:2.5"`
	CreatedAt           time.Time `gorm:"autoCreateTime"`
	UpdatedAt           time.Time `gorm:"autoUpdateTime"`
}

type UserGradeHistory struct {
	ID         int64     `gorm:"primaryKey;autoIncrement"`
	UserID     int64     `gorm:"not null;index"`
	GradeLevel int       `gorm:"not null"`
	StartDate  time.Time `gorm:"not null"`
	EndDate    *time.Time
	CreatedAt  time.Time `gorm:"autoCreateTime"`
}

// ================= 数学题库系统 =================
type KnowledgePoint struct {
	ID              int64     `gorm:"primaryKey;autoIncrement"`
	Name            string    `gorm:"size:100;not null"`
	Code            string    `gorm:"size:20;uniqueIndex;not null"`
	ParentID        *int64    `gorm:"index"`
	GradeLevel      int       `gorm:"not null"`
	DifficultyRange string    `gorm:"size:10;default:'1.0-5.0'"`
	Description     string    `gorm:"type:text"`
	IsActive        bool      `gorm:"default:true"`
	SortOrder       int       `gorm:"default:0"`
	CreatedAt       time.Time `gorm:"autoCreateTime"`
	UpdatedAt       time.Time `gorm:"autoUpdateTime"`
}

type Question struct {
	ID              int64   `gorm:"primaryKey;autoIncrement"`
	Title           string  `gorm:"size:200;not null"`
	Content         string  `gorm:"type:text;not null"`
	QuestionType    string  `gorm:"type:question_type;default:'single_choice'"`
	Difficulty      float64 `gorm:"type:decimal(3,2);not null"`
	GradeLevel      int     `gorm:"not null"`
	EstimatedTime   int     `gorm:"default:60"`
	CorrectAnswer   string  `gorm:"type:text;not null"`
	AnswerAnalysis  string  `gorm:"type:text"`
	Hints           JSONB   `gorm:"type:jsonb"`
	Choices         JSONB   `gorm:"type:jsonb"`
	Tags            JSONB   `gorm:"type:jsonb"`
	Source          string  `gorm:"size:100;default:''"`
	AuthorID        *int64
	ReviewStatus    string    `gorm:"type:review_status;default:'draft'"`
	UsageCount      int       `gorm:"default:0"`
	CorrectRate     float64   `gorm:"type:decimal(5,2);default:0.00"`
	AvgResponseTime int       `gorm:"default:0"`
	IsActive        bool      `gorm:"default:true"`
	CreatedAt       time.Time `gorm:"autoCreateTime"`
	UpdatedAt       time.Time `gorm:"autoUpdateTime"`
}

type QuestionKnowledgePoint struct {
	QuestionID       int64 `gorm:"primaryKey"`
	KnowledgePointID int64 `gorm:"primaryKey"`
}

// ================= 学习行为记录表 =================
type AnswerRecord struct {
	ID               int64     `gorm:"primaryKey;autoIncrement:false"`
	UserID           int64     `gorm:"not null;index"`
	QuestionID       int64     `gorm:"not null;index"`
	SessionID        string    `gorm:"size:64"`
	UserAnswer       string    `gorm:"type:text;not null"`
	IsCorrect        bool      `gorm:"not null"`
	ResponseTime     int       `gorm:"not null"`
	HintUsedCount    int       `gorm:"default:0"`
	DifficultyAtTime float64   `gorm:"type:decimal(3,2);not null"`
	ConfidenceScore  *float64  `gorm:"type:decimal(3,2)"`
	AnswerMethod     string    `gorm:"type:answer_method;default:'direct'"`
	IPAddress        string    `gorm:"type:inet"`
	DeviceInfo       JSONB     `gorm:"type:jsonb"`
	CreatedAt        time.Time `gorm:"primaryKey;autoCreateTime"`
}

type LearningSession struct {
	ID               int64     `gorm:"primaryKey;autoIncrement"`
	SessionID        string    `gorm:"size:64;uniqueIndex;not null"`
	UserID           int64     `gorm:"not null;index"`
	StartTime        time.Time `gorm:"not null"`
	EndTime          *time.Time
	QuestionsCount   int       `gorm:"default:0"`
	CorrectCount     int       `gorm:"default:0"`
	AvgDifficulty    float64   `gorm:"type:decimal(3,2);default:0.00"`
	SessionType      string    `gorm:"type:session_type;default:'practice'"`
	CompletionStatus string    `gorm:"type:completion_status;default:'ongoing'"`
	CreatedAt        time.Time `gorm:"autoCreateTime"`
	UpdatedAt        time.Time `gorm:"autoUpdateTime"`
}

// ================= AI系统相关表 =================
type DifficultyAdjustment struct {
	ID                int64     `gorm:"primaryKey;autoIncrement"`
	UserID            int64     `gorm:"not null;index"`
	OldDifficulty     float64   `gorm:"type:decimal(3,2);not null"`
	NewDifficulty     float64   `gorm:"type:decimal(3,2);not null"`
	AdjustmentReason  string    `gorm:"type:text;not null"`
	Confidence        float64   `gorm:"type:decimal(3,2);not null"`
	TriggerEvent      string    `gorm:"type:trigger_event;not null"`
	PerformanceWindow JSONB     `gorm:"type:jsonb"`
	CreatedAt         time.Time `gorm:"autoCreateTime"`
}

// ================= 系统配置表 =================
type SystemConfig struct {
	ID          int64     `gorm:"primaryKey;autoIncrement"`
	ConfigKey   string    `gorm:"size:100;uniqueIndex;not null"`
	ConfigValue string    `gorm:"type:text;not null"`
	ConfigType  string    `gorm:"type:config_type;default:'string'"`
	Description string    `gorm:"type:text"`
	IsActive    bool      `gorm:"default:true"`
	CreatedAt   time.Time `gorm:"autoCreateTime"`
	UpdatedAt   time.Time `gorm:"autoUpdateTime"`
}

// ================= 游戏化任务与奖励系统表 =================
type Reward struct {
	ID          int64     `gorm:"primaryKey;autoIncrement"`
	Name        string    `gorm:"size:100;not null"`
	Description string    `gorm:"type:text"`
	RewardType  string    `gorm:"type:reward_type;default:'points'"`
	Value       int       `gorm:"default:0"`
	CreatedAt   time.Time `gorm:"autoCreateTime"`
}

type Task struct {
	ID          int64  `gorm:"primaryKey;autoIncrement"`
	Name        string `gorm:"size:100;not null"`
	Description string `gorm:"type:text"`
	Type        string `gorm:"type:task_type;default:'daily'"`
	RewardID    *int64
	IsActive    bool      `gorm:"default:true"`
	CreatedAt   time.Time `gorm:"autoCreateTime"`
}

type UserTask struct {
	ID          int64  `gorm:"primaryKey;autoIncrement"`
	UserID      int64  `gorm:"not null;index"`
	TaskID      int64  `gorm:"not null;index"`
	Status      string `gorm:"type:task_status;default:'pending'"`
	Progress    int    `gorm:"default:0"`
	CompletedAt *time.Time
	CreatedAt   time.Time `gorm:"autoCreateTime"`
}

type UserReward struct {
	ID         int64     `gorm:"primaryKey;autoIncrement"`
	UserID     int64     `gorm:"not null;index"`
	RewardID   int64     `gorm:"not null;index"`
	ObtainedAt time.Time `gorm:"autoCreateTime"`
}
