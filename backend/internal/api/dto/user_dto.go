/*
File: user_dto.go
Author: lxp
Description: 用户相关的API数据传输对象 (DTOs)
*/
package dto

import "time"

// ================== 请求 (Request) ==================

// RegisterRequest 定义用户注册请求的结构体
type RegisterRequest struct {
	Username string `json:"username" binding:"required,min=4,max=20"`
	Password string `json:"password" binding:"required,min=6,max=30"`
	Email    string `json:"email" binding:"required,email"`
	Nickname string `json:"nickname" binding:"required,min=2,max=20"`
}

// LoginRequest 定义用户登录请求的结构体
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// UpdateUserRequest 定义更新用户信息请求的结构体
// 使用指针类型以支持部分更新 (PATCH-like behavior)
type UpdateUserRequest struct {
	Nickname   *string    `json:"nickname" binding:"omitempty,min=2,max=20"`
	AvatarURL  *string    `json:"avatar_url" binding:"omitempty,url"`
	GradeLevel *int       `json:"grade_level" binding:"omitempty,min=1,max=12"`
	BirthDate  *time.Time `json:"birth_date" binding:"omitempty"`
	Gender     *string    `json:"gender" binding:"omitempty,oneof=male female other"`
}

// ================== 响应 (Response) ==================

// UserResponse 是用于API返回的安全用户数据结构
type UserResponse struct {
	ID          int64      `json:"id"`
	Username    string     `json:"username"`
	Email       string     `json:"email"`
	Nickname    string     `json:"nickname"`
	AvatarURL   string     `json:"avatar_url"`
	GradeLevel  int        `json:"grade_level"`
	BirthDate   *time.Time `json:"birth_date"`
	Gender      string     `json:"gender"`
	Role        string     `json:"role"`
	CreatedAt   time.Time  `json:"created_at"`
	LastLoginAt *time.Time `json:"last_login_at"`
}

// RegisterResponse 是用于注册成功后返回的数据结构
type RegisterResponse struct {
	ID       int64  `json:"id"`
	Username string `json:"username"`
	Email    string `json:"email"`
	Nickname string `json:"nickname"`
}

// LoginResponse 定义用户登录响应的结构体
type LoginResponse struct {
	Token string        `json:"token"`
	User  *UserResponse `json:"user"`
}
