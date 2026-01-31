//
//  OCRService.swift
//  mac-toolkit
//
//  OCR service placeholder
//

import Foundation

actor OCRService {
    public static let shared = OCRService()

    private init() {}

    public func recognizeText(from image: Data) async throws -> String {
        throw NSError(domain: "OCRService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }
}
