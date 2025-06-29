/*
File: main.go
Author: lxp
Description: 网关服务入口
*/
package main

import (
	"fmt"
	"zhixue-backend/internal/config"
	"zhixue-backend/internal/gateway"
	"zhixue-backend/logger"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

func main() {
	// 初始化日志系统
	logger.InitLogger()
	defer logger.Cleanup()

	// 加载配置
	cfg, err := config.LoadConfig("./configs")
	if err != nil {
		logger.Logger.Fatal("网关配置加载失败", zap.Error(err))
	}

	logger.Logger.Info("🚀 启动智学奇境API网关",
		zap.String("version", cfg.App.Version),
		zap.Int("port", cfg.Gateway.Port))

	// 禁用Gin的默认日志输出
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()

	// 注册网关路由
	gateway.RegisterRoutes(r, cfg)

	// 启动服务器
	addr := fmt.Sprintf(":%d", cfg.Gateway.Port)
	logger.Logger.Info("API网关启动", zap.String("address", addr))
	if err := r.Run(addr); err != nil {
		logger.Logger.Fatal("API网关启动失败", zap.Error(err))
	}
}
