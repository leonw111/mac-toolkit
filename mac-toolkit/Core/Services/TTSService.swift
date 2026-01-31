//
//  TTSService.swift
//  mac-toolkit
//
//  TTS service placeholder
//

import Foundation

actor TTSService {
    public static let shared = TTSService()

    private init() {}

    public func speak(text: String) async throws {
        throw NSError(domain: "TTSService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])
    }
}
