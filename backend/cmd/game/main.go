/*
File: main.go
Author: lxp
Description: 智学奇境游戏服务器主入口 (Nano框架)
*/
package main

import (
	"log"
	"zhixue-backend/logger"

	"github.com/lonng/nano"
	"github.com/lonng/nano/component"
	"github.com/lonng/nano/serialize/json"
	"github.com/lonng/nano/session"
	"go.uber.org/zap"
)

type GameRoom struct {
	component.Base
}

type JoinRoomRequest struct {
	RoomID string `json:"roomId"`
	UserID string `json:"userId"`
}

type GameState struct {
	Players []string `json:"players"`
	Status  string   `json:"status"`
}

func (gr *GameRoom) JoinRoom(s *session.Session, req *JoinRoomRequest) error {
	logger.Logger.Info("用户加入房间",
		zap.String("user_id", req.UserID),
		zap.String("room_id", req.RoomID),
		zap.Int64("session_id", s.ID()),
	)

	logger.LogGameEvent(req.RoomID, "player_join", []string{req.UserID}, req)

	response := &GameState{
		Players: []string{req.UserID},
		Status:  "waiting",
	}

	return s.Response(response)
}

func (gr *GameRoom) GetRoomInfo(s *session.Session, req *JoinRoomRequest) error {
	logger.Logger.Info("获取房间信息",
		zap.String("room_id", req.RoomID),
		zap.Int64("session_id", s.ID()),
	)

	response := &GameState{
		Players: []string{"player1", "player2"},
		Status:  "playing",
	}

	return s.Response(response)
}

func main() {
	// 初始化日志系统
	logger.InitLogger()
	defer logger.Cleanup()

	// 注册游戏房间组件
	components := &component.Components{}
	components.Register(&GameRoom{})

	logger.Logger.Info("🎮 智学奇境游戏服务器启动",
		zap.String("framework", "Nano"),
		zap.String("port", "8002"),
		zap.String("protocol", "WebSocket"),
	)

	log.Println("🎮 智学奇境游戏服务器启动 (Nano框架) - 端口 8002")
	nano.Listen(":8002",
		nano.WithIsWebsocket(true),
		nano.WithSerializer(json.NewSerializer()),
		nano.WithComponents(components),
	)
}
