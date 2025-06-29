/*
File: middleware.go
Author: lxp
Description: 网关服务中间件
*/
package gateway

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"zhixue-backend/internal/config"
	"zhixue-backend/internal/redis"
	"zhixue-backend/logger"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"go.uber.org/zap"
)

type contextKey string

const (
	UserIDKey   contextKey = "UserID"
	UserRoleKey contextKey = "UserRole"
)

// AuthMiddleware 创建一个Gin中间件用于JWT认证
func AuthMiddleware(cfg *config.AuthConfig) gin.HandlerFunc {
	// 定义不需要认证的公开路由
	publicPaths := map[string]bool{
		"/api/v1/users/register": true,
		"/api/v1/users/login":    true,
	}

	return func(c *gin.Context) {
		// [DEBUG] 打印进入中间件的请求路径
		logger.Logger.Info("AuthMiddleware: checking request path", zap.String("path", c.Request.URL.Path))

		// 如果当前请求路径在公开路由列表中，则直接跳过认证
		if publicPaths[c.Request.URL.Path] {
			c.Next()
			return
		}

		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "缺少Authorization请求头"})
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Authorization请求头格式不正确"})
			return
		}

		tokenString := parts[1]

		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, jwt.ErrSignatureInvalid
			}
			return []byte(cfg.JWTSecret), nil
		})

		if err != nil {
			logger.Logger.Warn("JWT验证失败", zap.Error(err))
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "无效的Token"})
			return
		}

		if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
			jti, okJti := claims["jti"].(string)
			if !okJti {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Token格式不正确(缺少jti)"})
				return
			}

			// 检查jti是否在黑名单中
			blacklistKey := "jwt_blacklist:" + jti
			val, err := redis.Client.Get(context.Background(), blacklistKey).Result()
			if err == nil && val == "true" {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Token已失效(登出)"})
				return
			}

			// user_id 在 JWT claim 中是 float64 类型
			userIDFloat, ok1 := claims["user_id"].(float64)
			userRole, ok2 := claims["user_role"].(string)

			if !ok1 || !ok2 {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Token中缺少必要信息"})
				return
			}

			// 将 float64 类型的 userID 转换为字符串
			userID := fmt.Sprintf("%.0f", userIDFloat)

			// 将用户信息添加到请求头，以便后端服务获取
			c.Request.Header.Set("X-User-ID", userID)
			c.Request.Header.Set("X-User-Role", userRole)

			c.Next()
		} else {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "无效的Token Claims"})
		}
	}
}
