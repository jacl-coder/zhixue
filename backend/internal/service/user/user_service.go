/*
File: user_service.go
Author: lxp
Description: 用户服务业务逻辑
*/
package user

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
	"zhixue-backend/internal/api/dto"
	"zhixue-backend/internal/config"
	redis_pkg "zhixue-backend/internal/redis"
	"zhixue-backend/internal/repository/user"
	"zhixue-backend/models"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// Service 定义用户服务的接口
type Service interface {
	Register(username, password, email, nickname string) (*dto.RegisterResponse, error)
	Login(username, password string) (string, *dto.UserResponse, error)
	GetMe(userID int64) (*dto.UserResponse, error)
	UpdateMe(userID int64, req *dto.UpdateUserRequest) (*dto.UserResponse, error)
	Logout(authHeader string) error
}

// userService 实现了Service接口
type userService struct {
	repo   user.Repository
	config *config.Config
}

// NewUserService 创建一个新的用户服务实例
func NewUserService(repo user.Repository, config *config.Config) Service {
	return &userService{repo: repo, config: config}
}

// Register 处理用户注册逻辑
func (s *userService) Register(username, password, email, nickname string) (*dto.RegisterResponse, error) {
	// 哈希密码
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	// 创建用户模型
	newUser := &models.User{
		Username:     username,
		PasswordHash: string(hashedPassword),
		Email:        email,
		Nickname:     nickname,
		Role:         "user", // 默认角色
	}

	// 直接尝试创建用户，由仓库层处理唯一键冲突和事务
	err = s.repo.Create(newUser)
	if err != nil {
		// 如果错误是已知的唯一键冲突，直接返回以便handler层处理
		if errors.Is(err, user.ErrUsernameExists) || errors.Is(err, user.ErrEmailExists) || errors.Is(err, user.ErrDuplicateEntry) {
			return nil, err
		}
		// 对于其他未知错误，包装后返回
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return &dto.RegisterResponse{
		ID:       newUser.ID,
		Username: newUser.Username,
		Email:    newUser.Email,
		Nickname: newUser.Nickname,
	}, nil
}

// Login 处理用户登录逻辑
func (s *userService) Login(username, password string) (string, *dto.UserResponse, error) {
	// 获取用户信息
	user, err := s.repo.GetByUsername(username)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return "", nil, errors.New("用户不存在或密码错误")
		}
		return "", nil, err
	}

	// 验证密码
	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password))
	if err != nil {
		return "", nil, errors.New("用户不存在或密码错误")
	}

	// 更新登录时间
	now := time.Now()
	user.LastLoginAt = &now
	if s.repo.Update(user) != nil {
		return "", nil, errors.New("更新登录时间失败")
	}

	// 生成JWT
	jti := uuid.New().String()
	claims := jwt.MapClaims{
		"jti":       jti, // JWT唯一ID
		"user_id":   user.ID,
		"user_role": user.Role,
		"exp":       time.Now().Add(s.config.Auth.JWTExpires).Unix(),
		"iat":       time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(s.config.Auth.JWTSecret))
	if err != nil {
		return "", nil, err
	}

	userResponse := &dto.UserResponse{
		ID:          user.ID,
		Username:    user.Username,
		Email:       user.Email,
		Nickname:    user.Nickname,
		AvatarURL:   user.AvatarURL,
		GradeLevel:  user.GradeLevel,
		BirthDate:   user.BirthDate,
		Gender:      user.Gender,
		Role:        user.Role,
		CreatedAt:   user.CreatedAt,
		LastLoginAt: user.LastLoginAt, 
	}

	return tokenString, userResponse, nil
}

// GetMe 获取当前登录用户的信息
func (s *userService) GetMe(userID int64) (*dto.UserResponse, error) {
	user, err := s.repo.FindByID(userID)
	if err != nil {
		return nil, err // 错误可能是 gorm.ErrRecordNotFound
	}

	userResponse := &dto.UserResponse{
		ID:          user.ID,
		Username:    user.Username,
		Email:       user.Email,
		Nickname:    user.Nickname,
		AvatarURL:   user.AvatarURL,
		GradeLevel:  user.GradeLevel,
		BirthDate:   user.BirthDate,
		Gender:      user.Gender,
		Role:        user.Role,
		CreatedAt:   user.CreatedAt,
		LastLoginAt: user.LastLoginAt, 
	}

	return userResponse, nil
}

// UpdateMe 更新当前登录用户的信息
func (s *userService) UpdateMe(userID int64, req *dto.UpdateUserRequest) (*dto.UserResponse, error) {
	// 1. 获取当前用户
	user, err := s.repo.FindByID(userID)
	if err != nil {
		return nil, err // 包括 gorm.ErrRecordNotFound
	}

	// 2. 检查并更新字段
	if req.Nickname != nil {
		user.Nickname = *req.Nickname
	}
	if req.AvatarURL != nil {
		user.AvatarURL = *req.AvatarURL
	}
	if req.GradeLevel != nil {
		user.GradeLevel = *req.GradeLevel
	}
	if req.BirthDate != nil {
		user.BirthDate = req.BirthDate
	}
	if req.Gender != nil {
		user.Gender = *req.Gender
	}

	// 3. 将更新后的用户保存到数据库
	if err := s.repo.Update(user); err != nil {
		return nil, err
	}

	// 4. 返回更新后的用户信息
	updatedUserResponse := &dto.UserResponse{
		ID:          user.ID,
		Username:    user.Username,
		Email:       user.Email,
		Nickname:    user.Nickname,
		AvatarURL:   user.AvatarURL,
		GradeLevel:  user.GradeLevel,
		BirthDate:   user.BirthDate,
		Gender:      user.Gender,
		Role:        user.Role,
		CreatedAt:   user.CreatedAt,
		LastLoginAt: user.LastLoginAt, 
	}

	return updatedUserResponse, nil
}

// Logout 处理用户登出逻辑，将JWT加入黑名单
func (s *userService) Logout(authHeader string) error {
	// 1. 从 "Bearer <token>" 中提取 token
	tokenString := strings.TrimPrefix(authHeader, "Bearer ")
	if tokenString == authHeader { // 如果前缀不存在，说明格式错误
		return errors.New("authorization header格式不正确")
	}

	// 2. 解析Token以获取claims，注意：这里我们不需要验证签名，因为即使是过期的或无效的token，也没必要再加入黑名单
	// 我们使用 jwt.ParseUnverified 来避免因为token过期等错误导致无法拉黑
	token, _, err := new(jwt.Parser).ParseUnverified(tokenString, jwt.MapClaims{})
	if err != nil {
		return fmt.Errorf("无法解析token: %v", err)
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return errors.New("无法读取token claims")
	}

	// 3. 获取 jti 和 exp
	jti, ok := claims["jti"].(string)
	if !ok {
		return errors.New("token中缺少jti")
	}
	expFloat, ok := claims["exp"].(float64)
	if !ok {
		return errors.New("token中缺少exp")
	}
	exp := time.Unix(int64(expFloat), 0)

	// 4. 计算剩余过期时间
	// 如果token已经过期，duration会是负数，Redis的SetEX会自动处理，不会设置或立即过期
	duration := time.Until(exp)
	if duration <= 0 {
		return nil // Token已过期，无需拉黑
	}

	// 5. 将jti加入Redis黑名单
	blacklistKey := "jwt_blacklist:" + jti
	err = redis_pkg.Client.Set(context.Background(), blacklistKey, "true", duration).Err()
	if err != nil {
		return fmt.Errorf("无法将token加入黑名单: %v", err)
	}

	return nil
}
