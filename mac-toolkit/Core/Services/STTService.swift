//
//  STTService.swift
//  mac-toolkit
//
//  STT service placeholder
//

import Foundation

actor STTService {
    public static let shared = STTService()

    private init() {}

    public func transcribe(audio: Data) async throws -> String {
        throw NSError(domain: "STTService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }
}
