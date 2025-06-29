# backend 目录结构

本后端服务采用Golang开发，由 **API网关**、**HTTP业务服务** 和 **游戏服务器** 三部分构成。它们基于Gin和Nano框架，结合GORM等主流组件，为AI学习游戏平台提供高性能、可扩展的服务支撑。

- **API网关**: 作为系统的统一入口，负责请求路由、集中认证、日志记录等。
- **HTTP业务服务**: 实现用户、题库、学习记录、游戏化等核心业务API。
- **游戏服务器**: 通过TCP长连接为客户端提供实时交互能力。

系统通过gRPC与AI推理服务高效通信，数据存储采用PostgreSQL与Redis，保障数据一致性与访问效率。

```
├── cmd/                   # 应用程序入口
│   ├── gateway/           # API网关入口
│   ├── server/            # HTTP业务服务器入口
│   └── game/              # 游戏服务器入口
├── internal/              # 私有应用代码
│   ├── gateway/           # API网关核心逻辑 (路由、代理、中间件)
│   ├── api/               # HTTP业务API层
│   │   ├── handlers/      # HTTP处理器
│   │   ├── routes/        # 路由定义
│   │   ├── middleware/    # 中间件
│   │   └── proto/         # gRPC Protobuf定义
│   ├── service/           # 业务逻辑层
│   │   ├── user/          # 用户服务
│   │   ├── question/      # 题库服务
│   │   ├── learning/      # 学习记录服务
│   │   └── game/          # 游戏化服务
│   ├── repository/        # 数据访问层
│   │   ├── user/          # 用户数据访问
│   │   ├── question/      # 题库数据访问
│   │   └── learning/      # 学习记录数据访问
│   ├── config/            # 配置管理
│   ├── game/              # 游戏服务器逻辑
├── pkg/                   # 可复用库
│   ├── auth/              # 认证相关
│   ├── utils/             # 工具函数
│   └── errors/            # 错误处理
├── models/                # 数据模型
├── logger/                # 日志系统
├── configs/               # 配置文件
├── scripts/               # 构建和部署脚本
├── docs/                  # API文档
├── go.mod                 # Go模块定义
└── go.sum                 # Go模块校验
```
