/*
File: user_repository.go
Author: lxp
Description: 用户数据访问层
*/
package user

import (
	"zhixue-backend/models"

	"gorm.io/gorm"
)

// Repository 定义用户数据仓库的接口
type Repository interface {
	Create(user *models.User) error
	GetByUsername(username string) (*models.User, error)
	GetByEmail(email string) (*models.User, error)
	FindByID(id int64) (*models.User, error)
	Update(user *models.User) error
}

// userRepository 实现了Repository接口
type userRepository struct {
	db *gorm.DB
}

// NewUserRepository 创建一个新的用户数据仓库实例
func NewUserRepository(db *gorm.DB) Repository {
	return &userRepository{db: db}
}

// Create 在数据库中创建一个新用户
func (r *userRepository) Create(user *models.User) error {
	return r.db.Create(user).Error
}

// GetByUsername 通过用户名获取用户
func (r *userRepository) GetByUsername(username string) (*models.User, error) {
	var user models.User
	err := r.db.Where("username = ?", username).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// GetByEmail 通过邮箱获取用户
func (r *userRepository) GetByEmail(email string) (*models.User, error) {
	var user models.User
	err := r.db.Where("email = ?", email).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// FindByID 通过ID获取用户
func (r *userRepository) FindByID(id int64) (*models.User, error) {
	var user models.User
	err := r.db.First(&user, id).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// Update 更新数据库中的用户信息
func (r *userRepository) Update(user *models.User) error {
	return r.db.Save(user).Error
}
