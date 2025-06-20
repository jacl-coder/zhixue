# 智学奇境后端目录结构设计

## 📁 目录结构概览

```
backend/
├── cmd/                    # 应用程序入口
│   ├── server/            # HTTP服务器入口
│   └── game/              # 游戏服务器入口
├── internal/              # 私有应用程序代码
│   ├── api/               # API层 - HTTP路由和处理器
│   │   ├── handlers/      # HTTP处理器
│   │   ├── routes/        # 路由定义
│   │   └── middleware/    # 中间件
│   ├── service/           # 业务逻辑层
│   │   ├── user/          # 用户服务
│   │   ├── question/      # 题库服务
│   │   ├── learning/      # 学习记录服务
│   │   ├── ai/            # AI集成服务
│   │   └── game/          # 游戏化服务
│   ├── repository/        # 数据访问层
│   │   ├── user/          # 用户数据访问
│   │   ├── question/      # 题库数据访问
│   │   └── learning/      # 学习记录数据访问
│   ├── config/            # 配置管理
│   │   ├── config.go      # 配置结构
│   │   ├── database.go    # 数据库配置
│   │   └── redis.go       # Redis配置
│   └── game/              # 游戏服务器逻辑
│       ├── room/          # 房间管理
│       ├── session/       # 会话管理
│       └── events/        # 游戏事件
├── pkg/                   # 可被外部应用使用的库代码
│   ├── auth/              # 认证相关
│   │   ├── jwt.go         # JWT处理
│   │   └── bcrypt.go      # 密码加密
│   ├── utils/             # 工具函数
│   │   ├── response.go    # 统一响应格式
│   │   ├── validator.go   # 数据验证
│   │   └── converter.go   # 数据转换
│   └── errors/            # 错误处理
│       ├── codes.go       # 错误码定义
│       └── handler.go     # 错误处理器
├── models/                # 数据模型 (GORM)
│   ├── user.go            # 用户模型
│   ├── question.go        # 题目模型
│   ├── learning.go        # 学习记录模型
│   └── game.go            # 游戏相关模型
├── middleware/            # 全局中间件 (已存在)
├── logger/                # 日志系统 (已存在)
├── configs/               # 配置文件
│   ├── app.yaml          # 应用配置
│   ├── database.yaml     # 数据库配置
│   └── redis.yaml        # Redis配置
├── scripts/               # 构建和部署脚本
│   ├── build.sh          # 构建脚本
│   ├── deploy.sh         # 部署脚本
│   └── test.sh           # 测试脚本
├── docs/                  # API文档
│   ├── api.md            # API接口文档
│   └── swagger.yaml      # Swagger文档
├── go.mod                # Go模块定义 (已存在)
└── go.sum                # Go模块校验 (已存在)
```

## 🏗️ 架构设计原则

### 1. **分层架构** (Layered Architecture)
```
API层 (Handlers) → 服务层 (Services) → 仓库层 (Repository) → 数据层 (Models)
```

### 2. **依赖注入** (Dependency Injection)
- 使用接口定义依赖关系
- 便于单元测试和模块替换

### 3. **关注点分离** (Separation of Concerns)
- 每个包有明确的职责
- 业务逻辑与数据访问分离

### 4. **可测试性** (Testability)
- 每层都有对应的测试文件
- 模拟接口便于单元测试

## 📦 目录详细说明

### `/cmd` - 应用程序入口
**用途**: 包含应用程序的主要入口点
- `cmd/server/` - HTTP API服务器
- `cmd/game/` - Nano游戏服务器
- 每个入口都有自己的main函数

### `/internal` - 私有代码
**用途**: 只能被当前应用导入的私有代码

#### `/internal/api` - API层
- **handlers/**: HTTP请求处理器，处理路由逻辑
- **routes/**: 路由定义和分组
- **middleware/**: API层面的中间件

#### `/internal/service` - 业务逻辑层
- **user/**: 用户相关业务逻辑
- **question/**: 题库管理业务逻辑  
- **learning/**: 学习记录和分析业务逻辑
- **ai/**: AI服务集成业务逻辑
- **game/**: 游戏化功能业务逻辑

#### `/internal/repository` - 数据访问层
- 实现数据持久化接口
- 封装数据库操作
- 可以有多种实现 (PostgreSQL, Redis, 文件等)

### `/pkg` - 公共库代码
**用途**: 可以被外部应用使用的库代码

#### `/pkg/auth` - 认证授权
- JWT token生成和验证
- 密码加密和验证
- 权限检查

#### `/pkg/utils` - 工具函数
- 统一的响应格式
- 数据验证器
- 类型转换器

### `/models` - 数据模型
**用途**: GORM数据模型定义
- 对应数据库表结构
- 包含数据验证标签
- 定义表关联关系

### `/configs` - 配置文件
**用途**: 应用程序配置
- 不同环境的配置文件
- 数据库连接配置
- 第三方服务配置

## 🔄 数据流示例

### 用户注册流程
```
1. HTTP请求 → /internal/api/handlers/user.go
2. 数据验证 → /pkg/utils/validator.go
3. 业务逻辑 → /internal/service/user/user.go
4. 密码加密 → /pkg/auth/bcrypt.go
5. 数据持久化 → /internal/repository/user/user.go
6. 数据库操作 → /models/user.go
7. 响应格式化 → /pkg/utils/response.go
```

### AI难度调节流程
```
1. 答题记录 → /internal/api/handlers/learning.go
2. 学习分析 → /internal/service/learning/analysis.go
3. AI服务调用 → /internal/service/ai/difficulty.go
4. 难度更新 → /internal/repository/user/profile.go
5. 日志记录 → /logger/logger.go
```

## 🧪 测试策略

### 单元测试
```
internal/service/user/user_test.go
internal/repository/user/user_test.go
pkg/auth/jwt_test.go
pkg/utils/validator_test.go
```

### 集成测试
```
tests/integration/
├── api_test.go
├── database_test.go
└── redis_test.go
```

## 🚀 开发流程

### 1. **模型定义** (models/)
- 根据数据库设计创建GORM模型
- 定义数据验证规则

### 2. **仓库层** (internal/repository/)
- 实现数据访问接口
- 封装CRUD操作

### 3. **服务层** (internal/service/)
- 实现业务逻辑
- 调用仓库层和外部服务

### 4. **API层** (internal/api/)
- 实现HTTP处理器
- 定义路由和中间件

### 5. **测试验证**
- 单元测试各层逻辑
- 集成测试完整流程

## 🎯 优势特点

### 1. **可维护性**
- 清晰的目录结构
- 明确的职责分工
- 易于理解和修改

### 2. **可扩展性**
- 模块化设计
- 便于添加新功能
- 支持微服务拆分

### 3. **可测试性**
- 分层设计便于测试
- 接口抽象支持Mock
- 单元测试覆盖率高

### 4. **团队协作**
- 标准化的目录结构
- 清晰的代码组织
- 便于代码审查

这个目录结构遵循Go社区最佳实践，适合"智学奇境"这样的中大型项目！ 🚀
