/*
File: user_repository.go
Author: lxp
Description: 用户数据访问层
*/
package user

import (
	"errors"
	"zhixue-backend/models"

	"github.com/jackc/pgx/v5/pgconn"
	"gorm.io/gorm"
)

var (
	ErrUsernameExists = errors.New("username already exists")
	ErrEmailExists    = errors.New("email already exists")
	ErrDuplicateEntry = errors.New("duplicate entry")
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

// Create 在数据库中创建一个新用户，并处理唯一键冲突
func (r *userRepository) Create(user *models.User) error {
	err := r.db.Transaction(func(tx *gorm.DB) error {
		// 1. 创建用户
		if err := tx.Create(user).Error; err != nil {
			return err // 返回以便事务回滚
		}

		// 2. 创建关联的用户档案
		userProfile := models.UserProfile{
			UserID: user.ID,
			// 可以设置其他默认值
		}
		if err := tx.Create(&userProfile).Error; err != nil {
			return err // 返回以便事务回滚
		}

		// 事务成功提交
		return nil
	})

	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) {
			// PostgreSQL unique_violation error code
			if pgErr.Code == "23505" {
				switch pgErr.ColumnName {
				case "username":
					return ErrUsernameExists
				case "email":
					return ErrEmailExists
				default:
					return ErrDuplicateEntry
				}
			}
		}
	}
	return err
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
