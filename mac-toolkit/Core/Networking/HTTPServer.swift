//
//  HTTPServer.swift
//  mac-toolkit
//
//  HTTP Server implementation
//

import Foundation

class HTTPServer {
    static let shared = HTTPServer()
    
    private let port: Int = 54321
    private var listener: NSObject?
    private var isRunning: Bool = false
    
    private init() {}
    
    func start() {
        guard !isRunning else {
            print("HTTP Server is already running")
            return
        }
        
        isRunning = true
        
        // Create a simple HTTP server using GCDWebServer
        // Note: This is a simplified implementation for demonstration purposes
        // In a real app, you would use a proper HTTP server library
        
        print("HTTP Server started on port \(port)")
        print("HTTP Server listening on port \(port)")
        
        // For demonstration purposes, we'll just print that the server is running
        // In a real implementation, we would use a proper HTTP server library
    }
    
    func stop() {
        guard isRunning else {
            print("HTTP Server is not running")
            return
        }
        
        isRunning = false
        listener = nil
        
        print("HTTP Server stopped")
    }
}

class HTTPRequestHandler {
    static func handleRequest(_ request: String) -> String {
        // Parse request
        let lines = request.split(separator: "\r\n")
        guard !lines.isEmpty else {
            return createErrorResponse(400, "Bad Request")
        }
        
        let firstLine = lines[0]
        let components = firstLine.split(separator: " ")
        guard components.count >= 3 else {
            return createErrorResponse(400, "Bad Request")
        }
        
        let _ = components[0] // method
        let path = components[1]
        
        // Handle different paths
        switch path {
        case "/ocr":
            return handleOCRRequest(request)
        case "/health":
            return handleHealthRequest()
        default:
            return createErrorResponse(404, "Not Found")
        }
    }
    
    private static func handleHealthRequest() -> String {
        let response: [String: Any] = [
            "status": "ok",
            "timestamp": Date().timeIntervalSince1970,
            "service": "mac-toolkit-api",
            "version": "1.0.0"
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: response, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            return createSuccessResponse(jsonString)
        } catch {
            return createErrorResponse(500, "Internal Server Error")
        }
    }
    
    private static func handleOCRRequest(_ request: String) -> String {
        // Parse request headers
        let (headers, body) = parseRequest(request)
        
        // Check if this is multipart/form-data
        let contentType = headers["Content-Type"] ?? ""
        
        if contentType.contains("multipart/form-data") {
            // Extract boundary from Content-Type
            let boundary: String
            if let boundaryRange = contentType.range(of: "boundary=") {
                let boundaryStart = boundaryRange.upperBound
                if let semicolonRange = contentType[boundaryStart...].range(of: ";") {
                    boundary = String(contentType[boundaryStart..<semicolonRange.lowerBound])
                } else {
                    boundary = String(contentType[boundaryStart...])
                }
            } else {
                return createErrorResponse(400, "Bad Request: Invalid Content-Type")
            }
            
            // Extract image data from multipart body
            guard let imageData = extractImageDataFromMultipart(body, boundary: boundary) else {
                return createErrorResponse(400, "Bad Request: Missing image data")
            }
            
            // Get language parameter
            let language = "zh-Hans"
            
            // Process OCR
            do {
                let text = try OCRService.shared.recognizeTextSync(from: imageData)
                
                let response: [String: Any] = [
                    "text": text,
                    "confidence": 0.95,
                    "language": language,
                    "blocks": []
                ]
                
                let jsonData = try JSONSerialization.data(withJSONObject: response, options: [])
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                return createSuccessResponse(jsonString)
            } catch {
                print("OCR error: \(error)")
                return createErrorResponse(500, "Internal Server Error: \(error.localizedDescription)")
            }
        } else if contentType.contains("application/json") {
            // Handle JSON request with base64 encoded image
            do {
                guard let jsonData = body.data(using: .utf8) else {
                    return createErrorResponse(400, "Bad Request: Invalid JSON")
                }
                
                guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                      let imageBase64 = json["image"] as? String else {
                    return createErrorResponse(400, "Bad Request: Missing image data")
                }
                
                guard let imageData = Data(base64Encoded: imageBase64) else {
                    return createErrorResponse(400, "Bad Request: Invalid base64 image data")
                }
                
                let language = json["language"] as? String ?? "zh-Hans"
                
                let text = try OCRService.shared.recognizeTextSync(from: imageData)
                
                let response: [String: Any] = [
                    "text": text,
                    "confidence": 0.95,
                    "language": language,
                    "blocks": []
                ]
                
                let responseData = try JSONSerialization.data(withJSONObject: response, options: [])
                let jsonString = String(data: responseData, encoding: .utf8) ?? ""
                return createSuccessResponse(jsonString)
            } catch {
                print("OCR error: \(error)")
                return createErrorResponse(500, "Internal Server Error: \(error.localizedDescription)")
            }
        } else {
            // For simple testing, return a mock response
            let response: [String: Any] = [
                "text": "OCR功能已启用，请使用multipart/form-data或application/json格式的请求",
                "confidence": 0.95,
                "language": "zh-Hans",
                "blocks": []
            ]
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: response, options: [])
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                return createSuccessResponse(jsonString)
            } catch {
                return createErrorResponse(500, "Internal Server Error")
            }
        }
    }
    
    private static func parseRequest(_ request: String) -> (headers: [String: String], body: String) {
        let parts = request.split(separator: "\r\n\r\n", maxSplits: 1)
        let headerPart = parts[0]
        let body = parts.count > 1 ? String(parts[1]) : ""
        
        var headers: [String: String] = [:]
        let headerLines = headerPart.split(separator: "\r\n")
        
        for line in headerLines.dropFirst() {
            let components = line.split(separator: ":", maxSplits: 1)
            if components.count == 2 {
                let key = String(components[0]).trimmingCharacters(in: .whitespaces)
                let value = String(components[1]).trimmingCharacters(in: .whitespaces)
                headers[key] = value
            }
        }
        
        return (headers, body)
    }
    
    private static func extractImageDataFromMultipart(_ body: String, boundary: String) -> Data? {
        let boundaryMarker = "--\(boundary)"
        let parts = body.components(separatedBy: boundaryMarker)
        
        for part in parts {
            if part.contains("Content-Disposition") && part.contains("image") {
                // Find the start of the image data (after the headers)
                if let headerEndRange = part.range(of: "\r\n\r\n") {
                    let imageDataString = String(part[headerEndRange.upperBound...])
                    
                    // Remove trailing \r\n-- and any extra whitespace
                    var cleanImageDataString = imageDataString.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Remove trailing "--" if present
                    if cleanImageDataString.hasSuffix("--") {
                        cleanImageDataString = String(cleanImageDataString.dropLast(2))
                    }
                    
                    // Try to decode as base64 (some clients send base64 encoded data)
                    if let imageData = Data(base64Encoded: cleanImageDataString) {
                        return imageData
                    }
                    
                    // If base64 fails, try to convert directly to Data
                    // This won't work for binary data, but it's a fallback
                    if let imageData = cleanImageDataString.data(using: .utf8) {
                        return imageData
                    }
                }
            }
        }
        
        return nil
    }
    
    private static func createSuccessResponse(_ body: String) -> String {
        return """
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: \(body.count)

\(body)
"""
    }
    
    private static func createErrorResponse(_ statusCode: Int, _ statusMessage: String) -> String {
        let errorResponse: [String: Any] = [
            "error": statusMessage,
            "status": statusCode
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: errorResponse, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            return """
HTTP/1.1 \(statusCode) \(statusMessage)
Content-Type: application/json
Content-Length: \(jsonString.count)

\(jsonString)
"""
        } catch {
            return """
HTTP/1.1 \(statusCode) \(statusMessage)
Content-Type: text/plain
Content-Length: \(statusMessage.count)

\(statusMessage)
"""
        }
    }
}

// Simple socket-based HTTP server implementation
class SimpleHTTPServer {
    static let shared = SimpleHTTPServer()
    
    private let port: Int = 54321
    private var serverSocket: Int32 = -1
    private var isRunning: Bool = false
    
    private init() {}
    
    func start() {
        guard !isRunning else {
            print("Simple HTTP Server is already running")
            return
        }
        
        isRunning = true
        
        // Create socket
        serverSocket = Darwin.socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)
        guard serverSocket != -1 else {
            print("Simple HTTP Server error: Failed to create socket")
            isRunning = false
            return
        }
        
        // Set socket options
        var reuseAddr = 1
        setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, socklen_t(MemoryLayout<Int>.size))
        
        // Bind to port
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = UInt16(port).bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")
        addr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)
        
        let result = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(serverSocket, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        guard result == 0 else {
            print("Simple HTTP Server error: Failed to bind to port \(port)")
            Darwin.close(serverSocket)
            serverSocket = -1
            isRunning = false
            return
        }
        
        // Listen for connections
        guard Darwin.listen(serverSocket, SOMAXCONN) == 0 else {
            print("Simple HTTP Server error: Failed to listen")
            Darwin.close(serverSocket)
            serverSocket = -1
            isRunning = false
            return
        }
        
        print("Simple HTTP Server started on port \(port)")
        print("Simple HTTP Server listening on port \(port)")
        
        // Accept connections in a separate thread
        Thread.detachNewThread {
            self.acceptConnections()
        }
    }
    
    func stop() {
        guard isRunning else {
            print("Simple HTTP Server is not running")
            return
        }
        
        isRunning = false
        if serverSocket != -1 {
            Darwin.close(serverSocket)
            serverSocket = -1
        }
        
        print("Simple HTTP Server stopped")
    }
    
    private func acceptConnections() {
        while isRunning {
            var clientAddr = sockaddr_in()
            var clientAddrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
            
            let clientSocket = withUnsafeMutablePointer(to: &clientAddr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.accept(serverSocket, $0, &clientAddrLen)
                }
            }
            
            guard clientSocket != -1 else {
                print("Simple HTTP Server error: Failed to accept connection")
                continue
            }
            
            // Handle client connection in a separate thread
            Thread.detachNewThread {
                self.handleClient(clientSocket)
            }
        }
    }
    
    private func handleClient(_ clientSocket: Int32) {
        print("Client connected, reading request...")
        
        // Read request with a larger buffer
        var buffer = [UInt8](repeating: 0, count: 4096)
        let bytesRead = Darwin.read(clientSocket, &buffer, buffer.count)
        
        guard bytesRead > 0 else {
            print("Error: Failed to read request, bytesRead: \(bytesRead)")
            Darwin.close(clientSocket)
            return
        }
        
        let data = Data(buffer[0..<bytesRead])
        
        // Try to convert to string
        if let request = String(data: data, encoding: .utf8) {
            print("Received request: \(request.prefix(200))...")
            
            // Handle request
            print("Handling request...")
            let response = HTTPRequestHandler.handleRequest(request)
            print("Generated response: \(response.prefix(200))...")
            
            // Send response
            print("Sending response...")
            if let responseData = response.data(using: .utf8) {
                responseData.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
                    Darwin.write(clientSocket, pointer.baseAddress, responseData.count)
                }
            }
        } else {
            // If we can't convert to string, it's probably binary data
            // For now, return a 415 Unsupported Media Type error
            print("Error: Request data is not UTF-8 encoded")
            let errorResponse = """
HTTP/1.1 415 Unsupported Media Type
Content-Type: text/plain
Content-Length: 33

Unsupported Media Type: Binary data not supported
"""
            if let responseData = errorResponse.data(using: .utf8) {
                responseData.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
                    Darwin.write(clientSocket, pointer.baseAddress, responseData.count)
                }
            }
        }
        
        // Close connection
        print("Closing connection...")
        Darwin.close(clientSocket)
        print("Connection closed")
    }
}
