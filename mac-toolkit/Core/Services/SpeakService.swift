//
//  SpeakService.swift
//  mac-toolkit
//
//  Speak service implementation using AVSpeechSynthesizer
//

import Foundation
import AVFoundation

actor SpeakService {
    public static let shared = SpeakService()
    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    public func speak(text: String, language: String = "zh-CN") async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: language)
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
            utterance.volume = 1.0

            synthesizer.speak(utterance)
            continuation.resume()
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
    
    public func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
