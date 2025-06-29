/*
File: main.go
Author: lxp
Description: 智学奇境后端API服务主入口 (Gin框架)
*/
package main

import (
	"fmt"
	"zhixue-backend/internal/api/middleware"
	"zhixue-backend/internal/config"
	"zhixue-backend/internal/database"
	"zhixue-backend/internal/redis"
	"zhixue-backend/logger"

	// 依赖注入
	"zhixue-backend/internal/api/handlers"
	user_repo "zhixue-backend/internal/repository/user"
	user_service "zhixue-backend/internal/service/user"

	"github.com/gin-contrib/cors"
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
		logger.Logger.Fatal("配置加载失败", zap.Error(err))
	}

	// 初始化数据库
	if err := database.InitDatabase(&cfg.Database); err != nil {
		logger.Logger.Fatal("数据库初始化失败", zap.Error(err))
	}
	defer database.CloseDatabase()

	// 初始化Redis
	if err := redis.InitRedis(&cfg.Redis); err != nil {
		logger.Logger.Fatal("Redis初始化失败", zap.Error(err))
	}
	defer redis.CloseRedis()

	logger.Logger.Info("🚀 智学奇境API服务启动",
		zap.String("framework", "Gin + Nano"),
		zap.String("version", cfg.App.Version),
		zap.String("mode", cfg.App.Mode),
		zap.String("service_type", "HTTP API Server"))

	// 禁用Gin的默认日志输出
	gin.SetMode(gin.ReleaseMode)

	r := gin.New()

	// 使用自定义日志中间件
	r.Use(middleware.GinLogger())
	r.Use(middleware.GinRecovery())

	// 配置受信任的代理（安全配置）
	r.SetTrustedProxies([]string{"127.0.0.1", "::1"})

	// 允许跨域
	r.Use(cors.Default())

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		logger.Logger.Info("健康检查请求")

		// 检查数据库和Redis健康状态
		dbHealthy := database.IsHealthy()
		redisHealthy := redis.IsHealthy()

		status := "ok"
		if !dbHealthy || !redisHealthy {
			status = "degraded"
		}

		c.JSON(200, gin.H{
			"status":    status,
			"service":   "zhixue-backend",
			"framework": "Gin+Nano+Golang",
			"version":   cfg.App.Version,
			"database":  dbHealthy,
			"redis":     redisHealthy,
		})
	})

	// API路由
	api := r.Group("/api/v1")
	{
		api.GET("/test", func(c *gin.Context) {
			logger.LogUserAction("test_user", "api_test", map[string]interface{}{
				"endpoint": "/api/v1/test",
				"method":   "GET",
			})
			c.JSON(200, gin.H{"message": "智学奇境后端服务运行正常"})
		})
	}

	// 实例化Repository, Service, Handler
	userRepository := user_repo.NewUserRepository(database.DB)
	userService := user_service.NewUserService(userRepository, cfg)
	userHandler := handlers.NewUserHandler(userService)

	// 注册用户系统路由
	userRoutes := api.Group("/users")
	{
		userRoutes.POST("/register", userHandler.Register)
		userRoutes.POST("/login", userHandler.Login)
	}

	// 启动服务器
	logger.Logger.Info("启动HTTP服务器",
		zap.Int("port", cfg.App.Port),
		zap.String("address", fmt.Sprintf(":%d", cfg.App.Port)))

	if err := r.Run(fmt.Sprintf(":%d", cfg.App.Port)); err != nil {
		logger.Logger.Fatal("服务器启动失败", zap.Error(err))
	}
}
