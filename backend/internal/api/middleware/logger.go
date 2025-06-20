/*
File: logger.go
Author: lxp
Description: Gin中间件 - 日志记录中间件
*/
package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"zhixue-backend/logger"
)

// GinLogger Gin框架的Zap日志中间件
func GinLogger() gin.HandlerFunc {
	return gin.HandlerFunc(func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		raw := c.Request.URL.RawQuery

		// 处理请求
		c.Next()

		// 记录日志
		param := gin.LogFormatterParams{
			Latency:      time.Since(start),
			ClientIP:     c.ClientIP(),
			Method:       c.Request.Method,
			StatusCode:   c.Writer.Status(),
			ErrorMessage: c.Errors.ByType(gin.ErrorTypePrivate).String(),
			BodySize:     c.Writer.Size(),
		}

		if raw != "" {
			path = path + "?" + raw
		}

		// 根据状态码决定日志级别
		if param.StatusCode >= 500 {
			logger.Logger.Error("服务器错误",
				zap.Int("status", param.StatusCode),
				zap.String("method", param.Method),
				zap.String("path", path),
				zap.String("ip", param.ClientIP),
				zap.Duration("latency", param.Latency),
				zap.String("user_agent", c.Request.UserAgent()),
				zap.String("error", param.ErrorMessage),
			)
		} else if param.StatusCode >= 400 {
			logger.Logger.Warn("客户端错误",
				zap.Int("status", param.StatusCode),
				zap.String("method", param.Method),
				zap.String("path", path),
				zap.String("ip", param.ClientIP),
				zap.Duration("latency", param.Latency),
				zap.String("user_agent", c.Request.UserAgent()),
			)
		} else {
			logger.Logger.Info("请求处理",
				zap.Int("status", param.StatusCode),
				zap.String("method", param.Method),
				zap.String("path", path),
				zap.String("ip", param.ClientIP),
				zap.Duration("latency", param.Latency),
				zap.Int("size", param.BodySize),
			)
		}
	})
}

// GinRecovery 自定义的恢复中间件
func GinRecovery() gin.HandlerFunc {
	return gin.CustomRecovery(func(c *gin.Context, recovered interface{}) {
		logger.Logger.Error("Panic恢复",
			zap.Any("error", recovered),
			zap.String("path", c.Request.URL.Path),
			zap.String("method", c.Request.Method),
			zap.String("ip", c.ClientIP()),
		)
		c.JSON(500, gin.H{"error": "Internal Server Error"})
	})
}
