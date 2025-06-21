#!/bin/bash
# 智学奇境 - Ubuntu Server 22.04 最简环境搭建脚本 (Root用户)

set -e

echo "=============================================="
echo "智学奇境 - Ubuntu Server 环境搭建开始"
echo "=============================================="

# 系统更新
echo "1. 更新系统包..."
apt update && apt upgrade -y

# 安装基础工具
echo "2. 安装基础工具..."
apt install -y curl wget git vim unzip

# 安装 Go 1.23
echo "3. 安装 Go 1.23..."
cd /tmp
wget https://go.dev/dl/go1.23.0.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.zshrc
export PATH=$PATH:/usr/local/go/bin

# 安装 Python 3 和 pip
echo "4. 安装 Python 3..."
apt install -y python3 python3-pip python3-venv python3-dev
ln -sf /usr/bin/python3 /usr/bin/python
ln -sf /usr/bin/pip3 /usr/bin/pip

# 安装 PostgreSQL
echo "5. 安装 PostgreSQL..."
apt install -y postgresql postgresql-contrib
systemctl start postgresql
systemctl enable postgresql
sudo -u postgres psql -c "CREATE DATABASE zhixue_db;" 2>/dev/null || echo "数据库zhixue_db已存在，跳过创建"
sudo -u postgres psql -c "CREATE USER zhixue_user WITH PASSWORD '1024';" 2>/dev/null || echo "用户zhixue_user已存在，跳过创建"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE zhixue_db TO zhixue_user;"

# 安装 Redis
echo "6. 安装 Redis..."
apt install -y redis-server
systemctl start redis-server
systemctl enable redis-server

# 创建项目目录
echo "7. 创建项目目录..."
mkdir -p /root/zhixue/{backend,ai-service}
cd /root/zhixue

# 初始化 Go 后端
echo "8. 初始化 Go 后端..."
cd backend
go mod init zhixue-backend
# 安装必要的Go依赖
go get github.com/gin-gonic/gin
go get github.com/gin-contrib/cors
go get github.com/lonng/nano
go get gorm.io/gorm
go get gorm.io/driver/postgres
go get github.com/go-redis/redis/v8
go get github.com/golang-jwt/jwt/v5

cat > main.go << 'EOF'
package main

import (
	"log"
	"github.com/gin-gonic/gin"
	"github.com/gin-contrib/cors"
)

func main() {
	r := gin.Default()
	
	// 允许跨域
	r.Use(cors.Default())
	
	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "ok",
			"service": "zhixue-backend",
			"framework": "Gin + Nano",
		})
	})
	
	// API路由
	api := r.Group("/api/v1")
	{
		api.GET("/test", func(c *gin.Context) {
			c.JSON(200, gin.H{"message": "智学奇境后端服务运行正常"})
		})
	}
	
	log.Println("🚀 智学奇境后端启动 (Gin + Nano框架) - 端口 8001")
	r.Run(":8001")
}
EOF

# 创建Nano游戏服务器示例
cat > game_server.go << 'EOF'
package main

import (
	"log"
	"net/http"
	"github.com/lonng/nano"
	"github.com/lonng/nano/component"
	"github.com/lonng/nano/serialize/json"
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

func (gr *GameRoom) JoinRoom(s *nano.Session, req *JoinRoomRequest) error {
	log.Printf("用户 %s 加入房间 %s", req.UserID, req.RoomID)
	
	response := &GameState{
		Players: []string{req.UserID},
		Status:  "waiting",
	}
	
	return s.Response(response)
}

func (gr *GameRoom) GetRoomInfo(s *nano.Session, req *JoinRoomRequest) error {
	response := &GameState{
		Players: []string{"player1", "player2"},
		Status:  "playing",
	}
	
	return s.Response(response)
}

func startGameServer() {
	// 注册游戏房间组件
	nano.Register(&GameRoom{})
	
	// 启动Nano游戏服务器
	log.Println("🎮 智学奇境游戏服务器启动 (Nano框架) - 端口 8002")
	nano.Listen(":8002",
		nano.WithIsWebsocket(true),
		nano.WithSerializer(json.NewSerializer()),
	)
}

// 可以在main.go中调用: go startGameServer()
EOF

# 初始化 Python AI 服务
echo "9. 初始化 Python AI 服务..."
cd ../ai-service
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn
cat > main.py << 'EOF'
from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.get("/")
def root():
    return {"message": "智学奇境 AI 服务"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8003)
EOF

# 创建启动脚本
echo "10. 创建启动脚本..."
cd /root/zhixue
cat > start.sh << 'EOF'
#!/bin/bash
echo "启动智学奇境服务..."

# 启动后端
cd /root/zhixue/backend
nohup go run main.go > backend.log 2>&1 &
echo "后端服务已启动 (端口 8001)"

# 启动 AI 服务
cd /root/zhixue/ai-service
source venv/bin/activate
nohup python main.py > ai.log 2>&1 &
echo "AI 服务已启动 (端口 8003)"

echo "所有服务已启动完成！"
echo "后端健康检查: curl http://localhost:8001/health"
echo "AI 服务健康检查: curl http://localhost:8003/health"
echo "🎮 游戏服务器文件: /root/zhixue/backend/game_server.go"
EOF

chmod +x start.sh

echo "=============================================="
echo "环境搭建完成！"
echo "=============================================="
echo "项目路径: /root/zhixue"
echo "启动服务: cd /root/zhixue && ./start.sh"
echo "数据库: PostgreSQL (zhixue_db/zhixue_user/1024)"
echo "缓存: Redis (无密码)"
echo "后端: Go + Gin + Nano (端口 8001)"
echo "游戏服务器: Nano框架 (game_server.go)"
echo "AI服务: Python + FastAPI (端口 8003)"
echo "=============================================="
echo "请重启终端或执行: source /root/.zshrc"
echo "=============================================="