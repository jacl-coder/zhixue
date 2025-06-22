# 智学奇境 AI 数学学习平台 API 文档（MVP阶段）

本接口文档遵循 RESTful 风格设计，所有接口路径以 `/api/v1/` 为版本前缀。接口统一返回格式如下：

```json
{
  "code": 200,          // 200 表示成功，文档注释中会列出所有状态码
  "msg": "OK",          // 提示信息
  "data": { ... }       // 返回数据主体
}
````

## 状态码说明

* `200 OK`：请求成功，返回数据。
* `201 Created`：资源创建成功。
* `204 No Content`：请求成功，无返回数据。
* `301 Moved Permanently`：资源已被永久移动到新的 URI。
* `302 Found`：临时重定向，客户端应临时使用响应中的新 URI 访问资源。
* `303 See Other`：请求已完成，请客户端对 `Location` 指定的 URI 发起 GET 请求获取资源。
* `304 Not Modified`：资源未修改，客户端可继续使用缓存副本。
* `307 Temporary Redirect`：临时重定向，客户端应按原请求方法对新 URI 发起请求。
* `400 Bad Request`：请求语法错误或参数无效。
* `401 Unauthorized`：请求未提供有效身份验证信息。
* `403 Forbidden`：请求有效，但拒绝执行（权限不足）。
* `404 Not Found`：请求的资源不存在。
* `405 Method Not Allowed`：请求方法不被允许。
* `406 Not Acceptable`：请求的响应内容类型不被支持。
* `412 Precondition Failed`：请求中指定的条件未满足。
* `415 Unsupported Media Type`：请求的 `Content-Type` 不被支持。
* `500 Internal Server Error`：服务器内部错误。
* `501 Not Implemented`：服务器不支持请求方法或功能。

---

## 用户系统

| 方法   | 路径                       | 功能描述     |
| ---- | ------------------------ | -------- |
| POST | `/api/v1/users/register` | 用户注册     |
| POST | `/api/v1/users/login`    | 用户登录     |
| POST | `/api/v1/users/logout`   | 用户登出     |
| GET  | `/api/v1/users/me`       | 获取当前用户信息 |
| PUT  | `/api/v1/users/me`       | 更新当前用户信息 |

## 数学题库系统

| 方法   | 路径                              | 功能描述               |
| ---- | ------------------------------- | ------------------ |
| GET  | `/api/v1/questions`             | 获取题目列表（支持分页/筛选/推荐） |
| GET  | `/api/v1/questions/{id}`        | 获取题目详情             |
| POST | `/api/v1/questions/{id}/answer` | 提交题目答案             |
| GET  | `/api/v1/knowledge-points`      | 获取知识点列表            |

### 查询参数示例（GET `/api/v1/questions`）

| 参数                   | 类型     | 是否必填 | 说明                  |
| -------------------- | ------ | ---- | ------------------- |
| `page`               | int    | 否    | 页码，默认1              |
| `page_size`          | int    | 否    | 每页条数，默认20           |
| `knowledge_point_id` | int    | 否    | 按知识点筛选              |
| `difficulty`         | string | 否    | 按难度筛选，如 "简单"、"中等"   |
| `recommend`          | bool   | 否    | 是否返回AI推荐题目，true表示推荐 |

## 游戏化任务与奖励

| 方法   | 路径                         | 功能描述           |
| ---- | -------------------------- | -------------- |
| GET  | `/api/v1/tasks`            | 获取任务列表         |
| GET  | `/api/v1/tasks/{id}`       | 获取任务详情（包含当前进度） |
| POST | `/api/v1/tasks/{id}/claim` | 领取任务奖励         |

## 学习行为记录

| 方法   | 路径                          | 功能描述     |
| ---- | --------------------------- | -------- |
| POST | `/api/v1/learning-sessions` | 创建学习会话   |
| GET  | `/api/v1/learning-sessions` | 查询学习会话记录 |
| GET  | `/api/v1/answer-records`    | 查询答题记录   |

## 后台管理

### 题库管理

| 方法     | 路径                             | 功能描述            |
| ------ | ------------------------------ | --------------- |
| GET    | `/api/v1/admin/questions`      | 列出所有题目（支持分页/筛选） |
| POST   | `/api/v1/admin/questions`      | 添加新题目           |
| PUT    | `/api/v1/admin/questions/{id}` | 更新题目信息          |
| DELETE | `/api/v1/admin/questions/{id}` | 删除题目            |

### 用户管理

| 方法     | 路径                         | 功能描述            |
| ------ | -------------------------- | --------------- |
| GET    | `/api/v1/admin/users`      | 列出所有用户（支持分页/筛选） |
| GET    | `/api/v1/admin/users/{id}` | 获取用户详情          |
| PUT    | `/api/v1/admin/users/{id}` | 更新用户信息          |
| DELETE | `/api/v1/admin/users/{id}` | 删除用户            |

---

## 安全设计

* 所有需要身份验证的接口需在请求头中携带 Token：

  ```
  Authorization: Bearer <token>
  ```

* 登录成功返回：

  ```json
  {
    "code": 200,
    "msg": "OK",
    "data": {
      "token": "xxxxx.yyyyy.zzzzz",
      "refreshToken": null,
      "user": { "id": 1, "name": "张三" }
    }
  }
  ```

* 后台接口需额外校验管理员权限。

---

## 示例响应

### 成功（获取题目详情）

```json
{
  "code": 200,
  "msg": "OK",
  "data": {
    "id": 123,
    "title": "解方程：x² - 4 = 0",
    "difficulty": "中等",
    "knowledgePoint": "一元二次方程"
  }
}
```

### 失败（未授权）

```json
{
  "code": 401,
  "msg": "Unauthorized",
  "data": null
}
```

### 失败（资源未找到）

```json
{
  "code": 404,
  "msg": "Not Found",
  "data": null
}
```

---

## 分页响应示例（适用于题目列表、任务列表、用户列表等）

```json
{
  "code": 200,
  "msg": "OK",
  "data": {
    "items": [ ... ],        // 当前页数据列表
    "page": 1,               // 当前页码
    "pageSize": 20,         // 每页条数
    "totalItems": 100,      // 总条数
    "totalPages": 5         // 总页数
  }
}
```
