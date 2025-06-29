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
	"zhixue-backend/internal/api/response"
	user_repo "zhixue-backend/internal/repository/user"
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
		response.Error(c, http.StatusBadRequest, "参数绑定失败: "+err.Error())
		return
	}

	regResponse, err := h.service.Register(req.Username, req.Password, req.Email, req.Nickname)
	if err != nil {
		if errors.Is(err, user_repo.ErrUsernameExists) {
			response.Error(c, http.StatusConflict, "用户名已存在")
			return
		}
		if errors.Is(err, user_repo.ErrEmailExists) {
			response.Error(c, http.StatusConflict, "邮箱已被注册")
			return
		}
		if errors.Is(err, user_repo.ErrDuplicateEntry) {
			response.Error(c, http.StatusConflict, "重复注册，请检查输入")
			return
		}
		response.Error(c, http.StatusInternalServerError, "注册失败，请稍后重试")
		return
	}

	response.Success(c, http.StatusCreated, regResponse, "注册成功")
}

// Login 处理用户登录请求
func (h *UserHandler) Login(c *gin.Context) {
	var req dto.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "参数绑定失败: "+err.Error())
		return
	}

	token, user, err := h.service.Login(req.Username, req.Password)
	if err != nil {
		response.Error(c, http.StatusUnauthorized, "用户名或密码错误")
		return
	}

	response.Success(c, http.StatusOK, dto.LoginResponse{
		Token: token,
		User:  user,
	}, "登录成功")
}

// GetMe 处理获取当前用户信息的请求
func (h *UserHandler) GetMe(c *gin.Context) {
	userIDStr := c.Request.Header.Get("X-User-ID")
	if userIDStr == "" {
		response.Error(c, http.StatusUnauthorized, "无法获取用户信息，缺少X-User-ID头")
		return
	}

	userID, err := strconv.ParseInt(userIDStr, 10, 64)
	if err != nil {
		response.Error(c, http.StatusUnauthorized, "无法解析用户信息")
		return
	}

	userInfo, err := h.service.GetMe(userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.Error(c, http.StatusNotFound, "用户不存在")
			return
		}
		response.Error(c, http.StatusInternalServerError, "获取用户信息失败")
		return
	}

	response.Success(c, http.StatusOK, userInfo, "获取成功")
}

// UpdateMe 处理更新当前用户信息的请求
func (h *UserHandler) UpdateMe(c *gin.Context) {
	// 1. 从认证中间件注入的头中获取用户ID
	userIDStr := c.Request.Header.Get("X-User-ID")
	if userIDStr == "" {
		response.Error(c, http.StatusUnauthorized, "无法获取用户信息，缺少X-User-ID头")
		return
	}
	userID, err := strconv.ParseInt(userIDStr, 10, 64)
	if err != nil {
		response.Error(c, http.StatusUnauthorized, "无法解析用户信息")
		return
	}

	// 2. 绑定请求体到DTO
	var req dto.UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "参数绑定失败: "+err.Error())
		return
	}

	// 3. 调用服务层来处理业务逻辑
	updatedUser, err := h.service.UpdateMe(userID, &req)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.Error(c, http.StatusNotFound, "用户不存在")
			return
		}
		response.Error(c, http.StatusInternalServerError, "更新用户信息失败: "+err.Error())
		return
	}

	// 4. 返回成功响应
	response.Success(c, http.StatusOK, updatedUser, "用户信息更新成功")
}

// Logout 处理用户登出请求
func (h *UserHandler) Logout(c *gin.Context) {
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		response.Error(c, http.StatusUnauthorized, "缺少Authorization请求头")
		return
	}

	err := h.service.Logout(authHeader)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "登出失败: "+err.Error())
		return
	}

	response.Success(c, http.StatusOK, nil, "登出成功")
}

