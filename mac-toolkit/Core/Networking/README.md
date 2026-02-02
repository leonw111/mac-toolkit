# RESTful API Documentation

## Introduction

This document describes the RESTful API interface specifications for the macOS Toolkit application, including all available endpoints, request formats, response formats, and examples.

## API Basic Information

### Base URL
```
http://localhost:54321
```

### Response Structure

All API responses (except for binary data responses) use a unified JSON format:

#### Success Response
```json
{
  "code": 200,
  "message": "Operation successful",
  "data": {
    // Specific business data
  }
}
```

#### Error Response
```json
{
  "code": 400,
  "message": "Error message",
  "data": null
}
```

### HTTP Status Codes

| Status Code | Description |
|------------|-------------|
| 200 | Request successful |
| 400 | Invalid request parameters |
| 404 | Resource not found |
| 415 | Unsupported media type |
| 500 | Internal server error |

## API Endpoints

### 1. Health Check

**Endpoint**: `GET /api/health`

**Description**: Check if the service is running normally

**Request Parameters**: None

**Response Example**:
```json
{
  "code": 200,
  "message": "Service is normal",
  "data": {
    "status": "ok",
    "timestamp": 1643721600,
    "service": "mac-toolkit-api",
    "version": "1.0.0"
  }
}
```

### 2. OCR Recognition

**Endpoint**: `POST /api/ocr`

**Description**: Recognize text in images

**Request Formats**:

#### Form Data Format
```
Content-Type: multipart/form-data

// Form fields
image: [image file]
language: [language code, optional, default: zh-Hans]
```

#### JSON Format
```json
Content-Type: application/json

{
  "image": "[Base64 encoded image data]",
  "language": "zh-Hans" // optional, default: zh-Hans
}
```

**Response Example**:
```json
{
  "code": 200,
  "message": "Recognition successful",
  "data": {
    "text": "Recognized text content",
    "confidence": 0.95,
    "language": "zh-Hans",
    "blocks": []
  }
}
```

### 3. Text-to-Speech

**Endpoint**: `POST /api/tts`

**Description**: Convert text to speech file

**Request Format**:
```json
Content-Type: application/json

{
  "text": "Text to convert",
  "language": "zh-CN" // optional, default: zh-CN
}
```

**Response**: Binary MP3 file

**Response Headers**:
```
Content-Type: audio/mpeg
Content-Disposition: attachment; filename=speech.mp3
```

### 4. Speech Playback

**Endpoint**: `POST /api/speak`

**Description**: Play the specified text

**Request Format**:
```json
Content-Type: application/json

{
  "text": "Text to speak",
  "language": "zh-CN" // optional, default: zh-CN
}
```

**Response Example**:
```json
{
  "code": 200,
  "message": "Speech playback successful",
  "data": {
    "status": "success",
    "message": "Text spoken successfully",
    "text": "Text to speak",
    "language": "zh-CN"
  }
}
```

### 5. Stop Speech

**Endpoint**: `POST /api/speak/stop`

**Description**: Stop currently playing speech

**Request Parameters**: None

**Response Example**:
```json
{
  "code": 200,
  "message": "Speech stopped successfully",
  "data": {
    "status": "success",
    "message": "Speech stopped successfully"
  }
}
```

## Request Examples

### Health Check
```bash
curl -X GET http://localhost:54321/api/health
```

### OCR Recognition (Form Data)
```bash
curl -X POST http://localhost:54321/api/ocr \
  -F "image=@test.jpg" \
  -F "language=zh-Hans"
```

### OCR Recognition (JSON)
```bash
curl -X POST http://localhost:54321/api/ocr \
  -H "Content-Type: application/json" \
  -d '{
    "image": "base64_encoded_image_data",
    "language": "zh-Hans"
  }'
```

### Text-to-Speech
```bash
curl -X POST http://localhost:54321/api/tts \
  -H "Content-Type: application/json" \
  -d '{
    "text": "This is a test text",
    "language": "zh-CN"
  }' \
  -o speech.mp3
```

### Speech Playback
```bash
curl -X POST http://localhost:54321/api/speak \
  -H "Content-Type: application/json" \
  -d '{
    "text": "This is a test text",
    "language": "zh-CN"
  }'
```

### Stop Speech
```bash
curl -X POST http://localhost:54321/api/speak/stop
```

## Error Handling

When an API request fails, the server returns the corresponding error code and error message. Here are common error scenarios:

### 400 Bad Request
- Missing required request parameters
- Invalid request body format
- Invalid Base64 encoded image data

### 415 Unsupported Media Type
- Unsupported Content-Type in request
- Only application/json and multipart/form-data are supported (for OCR)

### 500 Internal Server Error
- Internal server processing error
- Service call failure

## Notes

1. All API calls require the macOS Toolkit application to be running locally
2. The Text-to-Speech API returns a binary MP3 file, not JSON format
3. The OCR API supports two request formats: form data and JSON
4. All API endpoints use the `/api/` prefix

## Version Information

- API Version: 1.0.0
- Last Updated: 2026-02-02
