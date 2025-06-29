/*
File: user_service.go
Author: lxp
Description: 用户服务业务逻辑
*/
package user

import (
	"errors"
	"time"
	"zhixue-backend/internal/config"
	"zhixue-backend/internal/repository/user"
	"zhixue-backend/models"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// Service 定义用户服务的接口
type Service interface {
	Register(username, password, email, nickname string) (*models.User, error)
	Login(username, password string) (string, *models.User, error)
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
func (s *userService) Register(username, password, email, nickname string) (*models.User, error) {
	// 检查用户名是否存在
	_, err := s.repo.GetByUsername(username)
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, errors.New("用户名已存在")
	}

	// 检查邮箱是否存在
	_, err = s.repo.GetByEmail(email)
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, errors.New("邮箱已被注册")
	}

	// 哈希密码
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	// 创建用户模型
	newUser := &models.User{
		Username:     username,
		PasswordHash: string(hashedPassword),
		Email:        email,
		Nickname:     nickname,
		Role:         "user", // 默认角色
	}

	// 保存到数据库
	err = s.repo.Create(newUser)
	if err != nil {
		return nil, err
	}

	return newUser, nil
}

// Login 处理用户登录逻辑
func (s *userService) Login(username, password string) (string, *models.User, error) {
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

	// 生成JWT
	claims := jwt.MapClaims{
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

	return tokenString, user, nil
}
