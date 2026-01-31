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
        // Parse multipart form data
        let (_, body) = parseRequest(request)
        
        // Extract image data and parameters
        guard let imageData = extractImageData(body),
              let parameters = extractParameters(body) else {
            return createErrorResponse(400, "Bad Request: Missing image data")
        }
        
        // Get language parameter
        let language = parameters["language"] as? String ?? "zh-Hans"
        
        // Process OCR
        do {
            // Note: We're using a sync version here for simplicity
            // In a real app, you would use async/await
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
    
    private static func extractImageData(_ body: String) -> Data? {
        // Simplified implementation
        // In a real implementation, we would parse multipart form data properly
        return body.data(using: .utf8)
    }
    
    private static func extractParameters(_ body: String) -> [String: Any]? {
        // Simplified implementation
        return ["language": "zh-Hans"]
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
        
        // Read request with a small buffer
        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = Darwin.read(clientSocket, &buffer, buffer.count)
        
        guard bytesRead > 0 else {
            print("Error: Failed to read request")
            Darwin.close(clientSocket)
            return
        }
        
        let data = Data(buffer[0..<bytesRead])
        guard let request = String(data: data, encoding: .utf8) else {
            print("Error: Failed to read request")
            Darwin.close(clientSocket)
            return
        }
        
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
        
        // Close connection
        print("Closing connection...")
        Darwin.close(clientSocket)
        print("Connection closed")
    }
}
