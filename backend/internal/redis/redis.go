/*
File: redis.go
Author: lxp
Description: Redis缓存连接和配置模块
*/
package redis

import (
	"context"
	"fmt"
	"time"

	"zhixue-backend/internal/config"
	"zhixue-backend/logger"

	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"
)

var Client *redis.Client
var ctx = context.Background()

// InitRedis 初始化Redis连接
func InitRedis(cfg *config.RedisConfig) error {
	Client = redis.NewClient(&redis.Options{
		Addr:         cfg.GetRedisAddr(),
		Password:     cfg.Password,
		DB:           cfg.Database,
		PoolSize:     cfg.PoolSize,
		MinIdleConns: cfg.MinIdleConns,
	})

	// 测试连接
	_, err := Client.Ping(ctx).Result()
	if err != nil {
		return fmt.Errorf("redis连接失败: %w", err)
	}

	logger.Logger.Info("Redis连接成功",
		zap.String("addr", cfg.GetRedisAddr()),
		zap.Int("database", cfg.Database),
		zap.Int("pool_size", cfg.PoolSize),
		zap.Int("min_idle_conns", cfg.MinIdleConns),
	)

	return nil
}

// GetClient 获取Redis客户端
func GetClient() *redis.Client {
	return Client
}

// CloseRedis 关闭Redis连接
func CloseRedis() error {
	if Client != nil {
		return Client.Close()
	}
	return nil
}

// IsHealthy 检查Redis健康状态
func IsHealthy() bool {
	if Client == nil {
		return false
	}

	_, err := Client.Ping(ctx).Result()
	return err == nil
}

// Set 设置键值对
func Set(key string, value interface{}, expiration time.Duration) error {
	return Client.Set(ctx, key, value, expiration).Err()
}

// Get 获取值
func Get(key string) (string, error) {
	return Client.Get(ctx, key).Result()
}

// Del 删除键
func Del(keys ...string) error {
	return Client.Del(ctx, keys...).Err()
}

// Exists 检查键是否存在
func Exists(keys ...string) (int64, error) {
	return Client.Exists(ctx, keys...).Result()
}

// Expire 设置过期时间
func Expire(key string, expiration time.Duration) error {
	return Client.Expire(ctx, key, expiration).Err()
}

// HSet 设置哈希字段
func HSet(key string, values ...interface{}) error {
	return Client.HSet(ctx, key, values...).Err()
}

// HGet 获取哈希字段值
func HGet(key, field string) (string, error) {
	return Client.HGet(ctx, key, field).Result()
}

// HGetAll 获取哈希所有字段
func HGetAll(key string) (map[string]string, error) {
	return Client.HGetAll(ctx, key).Result()
}
