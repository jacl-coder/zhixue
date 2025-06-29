/*
File: response.go
Author: lxp
Description: 统一API响应处理器
*/
package response

import (
	"github.com/gin-gonic/gin"
)

// ApiResponse 定义了标准的JSON响应结构体
// 确保所有API响应格式一致
type ApiResponse struct {
	Code int         `json:"code"`
	Msg  string      `json:"msg"`
	Data interface{} `json:"data"` // 始终包含data字段，即使其值为null
}

// sendResponse 是一个私有辅助函数，用于发送JSON响应
func sendResponse(c *gin.Context, httpStatus int, code int, msg string, data interface{}) {
	c.JSON(httpStatus, ApiResponse{
		Code: code,
		Msg:  msg,
		Data: data,
	})
}

// Success 发送一个标准的成功响应
// 使用HTTP状态码作为业务码，并提供一个默认"ok"消息
func Success(c *gin.Context, httpStatus int, data interface{}, msg ...string) {
	message := "操作成功"
	if len(msg) > 0 {
		message = msg[0]
	}
	sendResponse(c, httpStatus, httpStatus, message, data)
}

// Error 发送一个标准的错误响应
// 响应体将包含一个业务码、错误消息和为null的data字段
func Error(c *gin.Context, httpStatus int, msg string) {
	sendResponse(c, httpStatus, httpStatus, msg, nil)
}
