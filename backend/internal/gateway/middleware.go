/*
File: middleware.go
Author: lxp
Description: 网关服务中间件
*/
package gateway

import (
	"net/http"
	"strings"
	"zhixue-backend/internal/config"
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
	return func(c *gin.Context) {
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
			userID, ok1 := claims["user_id"].(string)
			userRole, ok2 := claims["user_role"].(string)

			if !ok1 || !ok2 {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Token中缺少必要信息"})
				return
			}

			// 将用户信息添加到请求头，以便后端服务获取
			c.Request.Header.Set("X-User-ID", userID)
			c.Request.Header.Set("X-User-Role", userRole)

			c.Next()
		} else {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "无效的Token Claims"})
		}
	}
}
