/*
File: logger.go
Author: lxp
Description: 统一日志管理模块 (基于Zap)
*/
package logger

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"gopkg.in/natefinch/lumberjack.v2"
)

var Logger *zap.Logger
var SugarLogger *zap.SugaredLogger

// customCallerEncoder 自定义调用者编码器，显示相对于项目根目录的路径
func customCallerEncoder(caller zapcore.EntryCaller, enc zapcore.PrimitiveArrayEncoder) {
	// 获取调用者的完整文件路径
	fullPath := caller.File

	// 查找项目根目录标识
	if idx := strings.Index(fullPath, "/backend/"); idx != -1 {
		// 提取项目内的相对路径
		relativePath := fullPath[idx+len("/backend/"):]
		enc.AppendString(fmt.Sprintf("%s:%d", relativePath, caller.Line))
	} else {
		// 如果找不到项目根，使用短路径
		enc.AppendString(fmt.Sprintf("%s:%d", filepath.Base(caller.File), caller.Line))
	}
}

// InitLogger 初始化日志系统
func InitLogger() {
	// 日志文件配置
	logFile := &lumberjack.Logger{
		Filename:   "./logs/zhixue.log", // 日志文件路径
		MaxSize:    100,                 // 单文件最大100MB
		MaxBackups: 30,                  // 保留30个备份文件
		MaxAge:     7,                   // 保留7天
		Compress:   true,                // 压缩备份文件
	}

	// 控制台输出配置
	consoleEncoderConfig := zap.NewDevelopmentEncoderConfig()
	consoleEncoderConfig.CallerKey = "caller"
	consoleEncoderConfig.EncodeCaller = customCallerEncoder // 使用自定义编码器
	consoleEncoder := zapcore.NewConsoleEncoder(consoleEncoderConfig)

	// 文件输出配置
	fileEncoderConfig := zap.NewProductionEncoderConfig()
	fileEncoderConfig.CallerKey = "caller"
	fileEncoderConfig.EncodeCaller = customCallerEncoder // 使用自定义编码器
	fileEncoder := zapcore.NewJSONEncoder(fileEncoderConfig)

	// 日志级别
	level := zapcore.InfoLevel
	if os.Getenv("DEBUG") == "true" {
		level = zapcore.DebugLevel
	}

	// 创建核心
	core := zapcore.NewTee(
		zapcore.NewCore(consoleEncoder, zapcore.AddSync(os.Stdout), level),
		zapcore.NewCore(fileEncoder, zapcore.AddSync(logFile), level),
	)

	// 创建Logger
	Logger = zap.New(core, zap.AddCaller(), zap.AddStacktrace(zapcore.ErrorLevel))
	SugarLogger = Logger.Sugar()

	// 替换全局logger
	zap.ReplaceGlobals(Logger)
}

// 业务相关的日志函数
func LogUserAction(userID, action string, metadata map[string]interface{}) {
	Logger.Info("用户行为",
		zap.String("user_id", userID),
		zap.String("action", action),
		zap.Any("metadata", metadata),
		zap.Time("timestamp", time.Now()),
	)
}

func LogGameEvent(roomID, eventType string, players []string, data interface{}) {
	Logger.Info("游戏事件",
		zap.String("room_id", roomID),
		zap.String("event_type", eventType),
		zap.Strings("players", players),
		zap.Any("data", data),
		zap.Time("timestamp", time.Now()),
	)
}

func LogAIRequest(userID, model string, inputSize int, processingTime time.Duration) {
	Logger.Info("AI请求",
		zap.String("user_id", userID),
		zap.String("model", model),
		zap.Int("input_size", inputSize),
		zap.Duration("processing_time", processingTime),
		zap.Time("timestamp", time.Now()),
	)
}

func LogError(component, operation string, err error, context map[string]interface{}) {
	Logger.Error("系统错误",
		zap.String("component", component),
		zap.String("operation", operation),
		zap.Error(err),
		zap.Any("context", context),
		zap.Time("timestamp", time.Now()),
	)
}

func LogPerformance(endpoint string, duration time.Duration, statusCode int, userID string) {
	Logger.Info("性能监控",
		zap.String("endpoint", endpoint),
		zap.Duration("duration", duration),
		zap.Int("status_code", statusCode),
		zap.String("user_id", userID),
		zap.Time("timestamp", time.Now()),
	)
}

// Cleanup 清理资源
func Cleanup() {
	if Logger != nil {
		Logger.Sync()
	}
}
