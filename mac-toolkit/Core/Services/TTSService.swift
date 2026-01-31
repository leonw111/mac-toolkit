//
//  TTSService.swift
//  mac-toolkit
//
//  TTS service implementation using AVFoundation
//  Converts text to audio file and returns audio data
//

import Foundation
import AVFoundation

actor TTSService {
    public static let shared = TTSService()

    private init() {}

    public func synthesize(text: String, language: String = "zh-CN") async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            print("TTS synthesize called with text: \(text), language: \(language)")
            
            // For testing purposes, immediately return dummy data
            // This will help us determine if the issue is with the speech synthesis or the audio capture
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { 
                print("Returning dummy audio data")
                let dummyData = Data()
                continuation.resume(returning: dummyData)
            }
        }
    }

    public func getAvailableVoices() -> [String] {
        return AVSpeechSynthesisVoice.speechVoices().map { $0.name }
    }

    public func getAvailableLanguages() -> [String] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        var languages: Set<String> = []
        
        for voice in voices {
            languages.insert(voice.language)
        }
        
        return Array(languages).sorted()
    }
}
