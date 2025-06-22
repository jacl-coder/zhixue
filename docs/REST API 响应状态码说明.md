# 智学奇境 REST API 响应状态码说明

## 2xx 成功响应

### 200 OK
表示 API 成功执行客户端请求的操作。通常返回响应主体，具体取决于请求方法：
- **GET**：返回所请求资源的实体。
- **HEAD**：返回实体的头字段，无消息体。
- **POST**：返回描述或包含操作结果的实体。
- **TRACE**：返回终端服务器接收的请求消息。

### 201 Created
表示已成功创建新资源。响应应包含 `Location` 头，指向新建资源的 URI。

### 202 Accepted
表示请求已被接受，但尚未完成处理。适用于异步或长时间执行的任务。建议返回状态监视或任务队列位置。

### 204 No Content
请求成功，但无返回内容。常用于 PUT、POST、DELETE 操作，不返回实体数据。

## 3xx 重定向

### 301 Moved Permanently
资源已被永久移动到新的 URI。新 URI 由 `Location` 头提供。

### 302 Found
临时重定向，客户端应临时使用响应中的新 URI 访问资源（通常用于浏览器，但不推荐用于 API 因可能导致 POST 变成 GET）

### 303 See Other
请求已完成，请客户端对 `Location` 指定的 URI 发起 GET 请求获取资源。

### 304 Not Modified
资源未修改，客户端可继续使用缓存副本。

### 307 Temporary Redirect
临时重定向。客户端应按原请求方法对新 URI 发起请求。

## 4xx 客户端错误

### 400 Bad Request
请求语法错误或参数无效。

### 401 Unauthorized
请求未提供有效身份验证信息。响应应包含 `WWW-Authenticate` 头。

### 403 Forbidden
请求有效，但拒绝执行（权限不足）。

### 404 Not Found
请求的资源不存在。

### 405 Method Not Allowed
请求方法不被允许。应返回 `Allow` 头指明允许的方法。

### 406 Not Acceptable
请求的响应内容类型不被支持（如客户端只接受 `application/xml`，而服务只返回 `application/json`）。

### 412 Precondition Failed
请求中指定的条件未满足。

### 415 Unsupported Media Type
请求的 `Content-Type` 不被支持。

## 5xx 服务器错误

### 500 Internal Server Error
服务器遇到意外错误，无法完成请求。

### 501 Not Implemented
服务器不支持请求方法或功能。

---

## 响应示例

成功：
```json
{
  "code": 0,
  "msg": "ok",
  "data": { ... }
}
````

失败：

```json
{
  "code": 400,
  "msg": "参数错误",
  "data": null
}
```

未授权：

```json
{
  "code": 401,
  "msg": "Unauthorized",
  "data": null
}
```
