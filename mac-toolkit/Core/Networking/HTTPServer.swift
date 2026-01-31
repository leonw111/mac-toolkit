//
//  HTTPServer.swift
//  mac-toolkit
//
//  Modern HTTP Server implementation using Network framework and Swift Concurrency
//

import Foundation
import Network

// MARK: - HTTP Server

@available(macOS 10.15, *)
actor HTTPServer {
    static let shared = HTTPServer()
    
    private let port: NWEndpoint.Port
    private var listener: NWListener?
    private var isRunning: Bool = false
    private var connections: Set<HTTPConnection> = []
    
    private init() {
        self.port = 54321
    }
    
    func start() async throws {
        guard !isRunning else {
            print("HTTP Server is already running")
            return
        }
        
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        params.acceptLocalOnly = true
        
        let listener = try NWListener(using: params, on: port)
        self.listener = listener
        
        listener.stateUpdateHandler = { [weak self] state in
            Task {
                await self?.handleListenerStateChange(state)
            }
        }
        
        listener.newConnectionHandler = { [weak self] connection in
            Task {
                await self?.handleNewConnection(connection)
            }
        }
        
        listener.start(queue: .main)
        isRunning = true
        
        print("HTTP Server started on port \(port)")
        print("HTTP Server listening on http://localhost:\(port)")
    }
    
    func stop() async {
        guard isRunning else {
            print("HTTP Server is not running")
            return
        }
        
        listener?.cancel()
        listener = nil
        
        // Close all active connections
        for connection in connections {
            await connection.close()
        }
        connections.removeAll()
        
        isRunning = false
        print("HTTP Server stopped")
    }
    
    private func handleListenerStateChange(_ state: NWListener.State) {
        switch state {
        case .ready:
            print("HTTP Server is ready to accept connections")
        case .failed(let error):
            print("HTTP Server failed: \(error)")
        case .cancelled:
            print("HTTP Server cancelled")
        default:
            break
        }
    }
    
    private func handleNewConnection(_ nwConnection: NWConnection) async {
        let connection = HTTPConnection(connection: nwConnection)
        connections.insert(connection)
        
        await connection.start { [weak self] in
            Task {
                await self?.removeConnection(connection)
            }
        }
    }
    
    private func removeConnection(_ connection: HTTPConnection) {
        connections.remove(connection)
    }
}

// MARK: - HTTP Connection

@available(macOS 10.15, *)
actor HTTPConnection: Hashable {
    private let connection: NWConnection
    private let id = UUID()
    
    init(connection: NWConnection) {
        self.connection = connection
    }
    
    func start(onComplete: @escaping () -> Void) async {
        connection.stateUpdateHandler = { [weak self] state in
            if case .ready = state {
                Task {
                    await self?.receiveRequest(onComplete: onComplete)
                }
            } else if case .failed(_) = state, case .cancelled = state {
                onComplete()
            }
        }
        
        connection.start(queue: .global(qos: .userInitiated))
    }
    
    func close() {
        connection.cancel()
    }
    
    private func receiveRequest(onComplete: @escaping () -> Void) async {
        // Read HTTP request (max 10MB for image uploads)
        let maxLength = 10 * 1024 * 1024
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: maxLength) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            Task {
                if let data = data, !data.isEmpty {
                    await self.handleRequest(data)
                }
                
                if isComplete || error != nil {
                    await self.close()
                    onComplete()
                }
            }
        }
    }
    
    private func handleRequest(_ data: Data) async {
        do {
            let request = try HTTPRequest.parse(from: data)
            let response = await processRequest(request)
            let responseData = response.toData()
            
            await sendResponse(responseData)
        } catch {
            print("Error parsing request: \(error)")
            let errorResponse = HTTPResponse.error(statusCode: 400, message: "Bad Request")
            await sendResponse(errorResponse.toData())
        }
    }
    
    private func processRequest(_ request: HTTPRequest) async -> HTTPResponse {
        switch (request.method, request.path) {
        case ("GET", "/health"):
            return handleHealthRequest()
            
        case ("POST", "/ocr"):
            return await handleOCRRequest(request)
            
        default:
            return HTTPResponse.error(statusCode: 404, message: "Not Found")
        }
    }
    
    private func handleHealthRequest() -> HTTPResponse {
        let response: [String: Any] = [
            "status": "ok",
            "timestamp": Date().timeIntervalSince1970,
            "service": "mac-toolkit-api",
            "version": "1.0.0"
        ]
        
        return HTTPResponse.json(response)
    }
    
    private func handleOCRRequest(_ request: HTTPRequest) async -> HTTPResponse {
        do {
            // Determine content type
            let contentType = request.headers["content-type"] ?? ""
            
            let imageData: Data
            let language: String
            
            if contentType.contains("multipart/form-data") {
                // Extract boundary
                guard let boundary = extractBoundary(from: contentType) else {
                    return HTTPResponse.error(statusCode: 400, message: "Missing boundary in multipart request")
                }
                
                // Parse multipart data
                guard let parsedData = parseMultipartFormData(request.body, boundary: boundary) else {
                    return HTTPResponse.error(statusCode: 400, message: "Failed to parse multipart data")
                }
                
                imageData = parsedData.imageData
                language = parsedData.language ?? "zh-Hans"
                
            } else if contentType.contains("application/json") {
                // Parse JSON request
                guard let json = try? JSONSerialization.jsonObject(with: request.body) as? [String: Any],
                      let imageBase64 = json["image"] as? String,
                      let decodedData = Data(base64Encoded: imageBase64) else {
                    return HTTPResponse.error(statusCode: 400, message: "Invalid JSON or missing image data")
                }
                
                imageData = decodedData
                language = json["language"] as? String ?? "zh-Hans"
                
            } else {
                return HTTPResponse.error(statusCode: 415, message: "Unsupported Media Type")
            }
            
            // Perform OCR using async method
            let text = try await OCRService.shared.recognizeText(from: imageData)
            
            let response: [String: Any] = [
                "text": text,
                "confidence": 0.95,
                "language": language,
                "blocks": []
            ]
            
            return HTTPResponse.json(response)
            
        } catch {
            print("OCR error: \(error)")
            return HTTPResponse.error(statusCode: 500, message: "Internal Server Error: \(error.localizedDescription)")
        }
    }
    
    private func sendResponse(_ data: Data) async {
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Error sending response: \(error)")
            }
        })
    }
    
    private func extractBoundary(from contentType: String) -> String? {
        guard let boundaryRange = contentType.range(of: "boundary=") else {
            return nil
        }
        
        let boundaryStart = contentType.index(boundaryRange.upperBound, offsetBy: 0)
        let remaining = contentType[boundaryStart...]
        
        if let semicolonIndex = remaining.firstIndex(of: ";") {
            return String(remaining[..<semicolonIndex])
        } else {
            return String(remaining)
        }
    }
    
    private func parseMultipartFormData(_ data: Data, boundary: String) -> (imageData: Data, language: String?)? {
        let boundaryData = "--\(boundary)".data(using: .utf8)!
        let crlfData = "\r\n".data(using: .utf8)!
        let doublecrlfData = "\r\n\r\n".data(using: .utf8)!
        
        // Split by boundary
        var parts: [Data] = []
        var searchRange = data.startIndex..<data.endIndex
        
        while let range = data.range(of: boundaryData, in: searchRange) {
            if searchRange.lowerBound < range.lowerBound {
                parts.append(data[searchRange.lowerBound..<range.lowerBound])
            }
            searchRange = range.upperBound..<data.endIndex
        }
        
        // Process each part
        var imageData: Data?
        var language: String?
        
        for part in parts {
            // Find header/body separator
            guard let separatorRange = part.range(of: doublecrlfData) else {
                continue
            }
            
            let headerData = part[part.startIndex..<separatorRange.lowerBound]
            var bodyData = part[separatorRange.upperBound..<part.endIndex]
            
            // Remove trailing CRLF
            if bodyData.count >= 2 && bodyData.suffix(2) == crlfData {
                bodyData = bodyData.dropLast(2)
            }
            
            // Parse headers
            guard let headerString = String(data: headerData, encoding: .utf8) else {
                continue
            }
            
            // Check if this is an image part
            if headerString.contains("Content-Disposition") && 
               (headerString.contains("filename") || headerString.contains("image")) {
                imageData = bodyData
            }
            
            // Check for language field
            if headerString.contains("name=\"language\"") {
                if let langString = String(data: bodyData, encoding: .utf8) {
                    language = langString.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        guard let finalImageData = imageData else {
            return nil
        }
        
        return (finalImageData, language)
    }
    
    // Hashable conformance
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    nonisolated static func == (lhs: HTTPConnection, rhs: HTTPConnection) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - HTTP Request

struct HTTPRequest: Sendable {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Data
    
    nonisolated static func parse(from data: Data) throws -> HTTPRequest {
        // Find header/body separator
        let separatorData = "\r\n\r\n".data(using: .utf8)!
        
        guard let separatorRange = data.range(of: separatorData) else {
            throw HTTPError.invalidRequest
        }
        
        let headerData = data[data.startIndex..<separatorRange.lowerBound]
        let body = data[separatorRange.upperBound..<data.endIndex]
        
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            throw HTTPError.invalidRequest
        }
        
        // Parse request line and headers
        let lines = headerString.components(separatedBy: "\r\n")
        guard !lines.isEmpty else {
            throw HTTPError.invalidRequest
        }
        
        // Parse request line (e.g., "GET /path HTTP/1.1")
        let requestLine = lines[0].split(separator: " ")
        guard requestLine.count >= 3 else {
            throw HTTPError.invalidRequest
        }
        
        let method = String(requestLine[0])
        let path = String(requestLine[1])
        
        // Parse headers
        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let colonIndex = line.firstIndex(of: ":") else {
                continue
            }
            
            let key = line[..<colonIndex].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
            headers[key] = value
        }
        
        return HTTPRequest(method: method, path: path, headers: headers, body: body)
    }
}

// MARK: - HTTP Response

struct HTTPResponse: Sendable {
    let statusCode: Int
    let statusMessage: String
    let headers: [String: String]
    let body: Data
    
    nonisolated func toData() -> Data {
        var response = "HTTP/1.1 \(statusCode) \(statusMessage)\r\n"
        
        for (key, value) in headers {
            response += "\(key): \(value)\r\n"
        }
        
        response += "Content-Length: \(body.count)\r\n"
        response += "\r\n"
        
        var data = response.data(using: .utf8)!
        data.append(body)
        
        return data
    }
    
    nonisolated static func json(_ object: [String: Any], statusCode: Int = 200) -> HTTPResponse {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return error(statusCode: 500, message: "Failed to encode JSON")
        }
        
        return HTTPResponse(
            statusCode: statusCode,
            statusMessage: statusMessage(for: statusCode),
            headers: ["Content-Type": "application/json"],
            body: jsonData
        )
    }
    
    nonisolated static func error(statusCode: Int, message: String) -> HTTPResponse {
        let errorObject: [String: Any] = [
            "error": message,
            "status": statusCode
        ]
        
        return json(errorObject, statusCode: statusCode)
    }
    
    nonisolated private static func statusMessage(for code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 415: return "Unsupported Media Type"
        case 500: return "Internal Server Error"
        default: return "Unknown"
        }
    }
}

// MARK: - HTTP Error
enum HTTPError: Error, Sendable {
    case invalidRequest
    case unsupportedMethod
    case notFound
}


