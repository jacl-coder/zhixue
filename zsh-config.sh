# 智学奇境项目 - Zsh环境配置
# 将此文件内容添加到 /root/.zshrc

# Go环境变量
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/opt/go
export PATH=$PATH:$GOPATH/bin

# Python环境变量
export PYTHONPATH=/root/zhixue/ai-service

# 项目快捷命令
alias zhixue="cd /root/zhixue"
alias zhixue-backend="cd /root/zhixue/backend"
alias zhixue-ai="cd /root/zhixue/ai-service && source venv/bin/activate"
alias zhixue-start="cd /root/zhixue && ./start.sh"

# 数据库连接快捷命令
alias zhixue-db="psql -h localhost -U zhixue_user -d zhixue_db"
alias zhixue-redis="redis-cli"

# 开发工具快捷命令
alias go-run="go run main.go"
alias go-build="go build -o zhixue-backend main.go"
alias py-run="source venv/bin/activate && python main.py"
alias py-dev="source venv/bin/activate && uvicorn main:app --reload --host 0.0.0.0 --port 8003"

echo "🎯 智学奇境开发环境已加载 (Zsh)"
echo "📁 项目目录: /root/zhixue"
echo "🔧 快捷命令: zhixue, zhixue-backend, zhixue-ai, zhixue-start"
