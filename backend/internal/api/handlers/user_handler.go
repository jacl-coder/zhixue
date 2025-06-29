/*
File: user_handler.go
Author: lxp
Description: 用户API处理器
*/
package handlers

import (
	"errors"
	"net/http"
	"strconv"
	"zhixue-backend/internal/api/dto"
	"zhixue-backend/internal/service/user"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// UserHandler 封装了用户相关的API处理器
type UserHandler struct {
	service user.Service
}

// NewUserHandler 创建一个新的UserHandler
func NewUserHandler(service user.Service) *UserHandler {
	return &UserHandler{service: service}
}

// Register 处理用户注册请求
func (h *UserHandler) Register(c *gin.Context) {
	var req dto.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := h.service.Register(req.Username, req.Password, req.Email, req.Nickname)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"code":    http.StatusCreated,
		"message": "注册成功",
		"data":    user,
	})
}

// Login 处理用户登录请求
func (h *UserHandler) Login(c *gin.Context) {
	var req dto.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	token, user, err := h.service.Login(req.Username, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 200,
		"msg":  "OK",
		"data": dto.LoginResponse{
			Token: token,
			User:  user,
		},
	})
}

// GetMe 处理获取当前用户信息的请求
func (h *UserHandler) GetMe(c *gin.Context) {
	userIDStr := c.Request.Header.Get("X-User-ID")
	if userIDStr == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "无法获取用户信息，缺少X-User-ID头"})
		return
	}

	userID, err := strconv.ParseInt(userIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "无法解析用户信息"})
		return
	}

	userInfo, err := h.service.GetMe(userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "用户不存在"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取用户信息失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 200,
		"msg":  "OK",
		"data": userInfo,
	})
}

// UpdateMe 处理更新当前用户信息的请求
func (h *UserHandler) UpdateMe(c *gin.Context) {
	// 1. 从认证中间件注入的头中获取用户ID
	userIDStr := c.Request.Header.Get("X-User-ID")
	if userIDStr == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "无法获取用户信息，缺少X-User-ID头"})
		return
	}
	userID, err := strconv.ParseInt(userIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "无法解析用户信息"})
		return
	}

	// 2. 绑定请求体到DTO
	var req dto.UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 3. 调用服务层来处理业务逻辑
	updatedUser, err := h.service.UpdateMe(userID, &req)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "用户不存在"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "更新用户信息失败: " + err.Error()})
		return
	}

	// 4. 返回成功响应
	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"message": "用户信息更新成功",
		"data":    updatedUser,
	})
}

// Logout 处理用户登出请求
func (h *UserHandler) Logout(c *gin.Context) {
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "缺少Authorization请求头"})
		return
	}

	err := h.service.Logout(authHeader)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "登出失败: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"message": "登出成功",
	})
}
