/*
File: routes.go
Author: lxp
Description: 网关服务路由配置
*/
package gateway

import (
	"fmt"
	"zhixue-backend/internal/api/middleware"
	"zhixue-backend/internal/config"
	"zhixue-backend/logger"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// RegisterRoutes 注册网关的所有路由
func RegisterRoutes(r *gin.Engine, cfg *config.Config) {
	r.SetTrustedProxies([]string{"127.0.0.1", "::1"})
	r.Use(middleware.GinLogger())
	r.Use(middleware.GinRecovery())

	// 创建指向后端API服务的反向代理
	backendAPIProxy, err := NewReverseProxy(fmt.Sprintf("http://localhost:%d", cfg.App.Port))
	if err != nil {
		logger.Logger.Fatal("创建后端API代理失败", zap.Error(err))
	}

	// 创建指向AI服务的反向代理
	aiServiceProxy, err := NewReverseProxy(cfg.AIService.URL)
	if err != nil {
		logger.Logger.Fatal("创建AI服务代理失败", zap.Error(err))
	}

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "ok",
			"service": "api-gateway",
			"version": cfg.App.Version,
		})
	})

	// V1 API 路由组
	// AuthMiddleware 将智能地跳过白名单中的 /register 和 /login 路由
	apiV1 := r.Group("/api/v1")
	apiV1.Use(AuthMiddleware(&cfg.Auth))
	{
		// 将所有 /api/v1/* 的请求都代理到后端API服务
		apiV1.Any("/*path", backendAPIProxy)
	}

	// AI 服务路由组 (所有AI路由都需要认证)
	ai := r.Group("/ai")
	ai.Use(AuthMiddleware(&cfg.Auth))
	{
		// 将所有/ai的请求转发到AI服务
		ai.Any("/*path", aiServiceProxy)
	}
}
