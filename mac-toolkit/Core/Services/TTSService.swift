//
//  TTSService.swift
//  mac-toolkit
//
//  TTS service placeholder for future implementation
//  Will be used to generate audio files from text
//

import Foundation

actor TTSService {
    public static let shared = TTSService()

    private init() {}

    // TODO: Implement text-to-speech conversion to audio file
    public func synthesize(text: String, language: String = "zh-CN") async throws -> Data {
        throw NSError(domain: "TTSService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"])    }

    // TODO: Implement getAvailableVoices
    public func getAvailableVoices() -> [String] {
        return []
    }

    // TODO: Implement getAvailableLanguages
    public func getAvailableLanguages() -> [String] {
        return []
    }
}
