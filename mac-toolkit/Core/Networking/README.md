# RESTful API 文档

## 简介

本文档描述了 macOS Toolkit 应用的 RESTful API 接口规范，包括所有可用的端点、请求格式、响应格式和示例。

## API 基础信息

### 基础 URL
```
http://localhost:54321
```

### 响应结构

所有 API 响应（除了二进制数据响应）都使用统一的 JSON 格式：

#### 成功响应
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    // 具体业务数据
  }
}
```

#### 错误响应
```json
{
  "code": 400,
  "message": "错误信息",
  "data": null
}
```

### HTTP 状态码

| 状态码 | 描述 |
|-------|------|
| 200 | 请求成功 |
| 400 | 请求参数错误 |
| 404 | 资源不存在 |
| 415 | 不支持的媒体类型 |
| 500 | 服务器内部错误 |

## API 端点

### 1. 健康检查

**端点**: `GET /api/health`

**描述**: 检查服务是否正常运行

**请求参数**: 无

**响应示例**:
```json
{
  "code": 200,
  "message": "服务正常",
  "data": {
    "status": "ok",
    "timestamp": 1643721600,
    "service": "mac-toolkit-api",
    "version": "1.0.0"
  }
}
```

### 2. OCR 识别

**端点**: `POST /api/ocr`

**描述**: 识别图像中的文字

**请求格式**:

#### 表单数据格式
```
Content-Type: multipart/form-data

// 表单字段
image: [图片文件]
language: [语言代码，可选，默认为 zh-Hans]
```

#### JSON 格式
```json
Content-Type: application/json

{
  "image": "[Base64 编码的图片数据]",
  "language": "zh-Hans" // 可选，默认为 zh-Hans
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "识别成功",
  "data": {
    "text": "识别的文字内容",
    "confidence": 0.95,
    "language": "zh-Hans",
    "blocks": []
  }
}
```

### 3. 语音合成

**端点**: `POST /api/tts`

**描述**: 将文本转换为语音文件

**请求格式**:
```json
Content-Type: application/json

{
  "text": "要转换的文本",
  "language": "zh-CN" // 可选，默认为 zh-CN
}
```

**响应**: 二进制 MP3 文件

**响应头**:
```
Content-Type: audio/mpeg
Content-Disposition: attachment; filename=speech.mp3
```

### 4. 语音播放

**端点**: `POST /api/speak`

**描述**: 播放指定的文本

**请求格式**:
```json
Content-Type: application/json

{
  "text": "要播放的文本",
  "language": "zh-CN" // 可选，默认为 zh-CN
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "语音播放成功",
  "data": {
    "status": "success",
    "message": "Text spoken successfully",
    "text": "要播放的文本",
    "language": "zh-CN"
  }
}
```

### 5. 停止语音

**端点**: `POST /api/speak/stop`

**描述**: 停止当前正在播放的语音

**请求参数**: 无

**响应示例**:
```json
{
  "code": 200,
  "message": "语音停止成功",
  "data": {
    "status": "success",
    "message": "Speech stopped successfully"
  }
}
```

## 请求示例

### 健康检查
```bash
curl -X GET http://localhost:54321/api/health
```

### OCR 识别（表单数据）
```bash
curl -X POST http://localhost:54321/api/ocr \
  -F "image=@test.jpg" \
  -F "language=zh-Hans"
```

### OCR 识别（JSON）
```bash
curl -X POST http://localhost:54321/api/ocr \
  -H "Content-Type: application/json" \
  -d '{
    "image": "base64_encoded_image_data",
    "language": "zh-Hans"
  }'
```

### 语音合成
```bash
curl -X POST http://localhost:54321/api/tts \
  -H "Content-Type: application/json" \
  -d '{
    "text": "这是一段测试文本",
    "language": "zh-CN"
  }' \
  -o speech.mp3
```

### 语音播放
```bash
curl -X POST http://localhost:54321/api/speak \
  -H "Content-Type: application/json" \
  -d '{
    "text": "这是一段测试文本",
    "language": "zh-CN"
  }'
```

### 停止语音
```bash
curl -X POST http://localhost:54321/api/speak/stop
```

## 错误处理

当 API 请求失败时，服务器会返回相应的错误代码和错误信息。以下是常见的错误情况：

### 400 Bad Request
- 缺少必要的请求参数
- 请求体格式错误
- 无效的 Base64 编码图像数据

### 415 Unsupported Media Type
- 请求的 Content-Type 不支持
- 仅支持 application/json 和 multipart/form-data（对于 OCR）

### 500 Internal Server Error
- 服务器内部处理错误
- 服务调用失败

## 注意事项

1. 所有 API 调用都需要在本地运行 macOS Toolkit 应用
2. 语音合成 API 返回的是二进制 MP3 文件，不是 JSON 格式
3. OCR API 支持两种请求格式：表单数据和 JSON
4. 所有 API 端点都使用 `/api/` 前缀

## 版本信息

- API 版本: 1.0.0
- 最后更新: 2026-02-02
