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

    public func speak(
        text: String, 
        language: String = "zh-CN", 
        voiceName: String? = nil, 
        rate: Float? = nil, 
        pitchMultiplier: Float? = nil, 
        volume: Float? = nil
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let utterance = AVSpeechUtterance(string: text)
            
            // 优先使用指定的声音名称
            if let voiceName = voiceName, 
               let voice = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.name == voiceName }) {
                utterance.voice = voice
            } else {
                // 回退到按语言选择
                utterance.voice = AVSpeechSynthesisVoice(language: language)
            }
            
            // 设置语速（默认 0.5）
            utterance.rate = rate ?? 0.5
            // 设置音调（默认 1.0）
            utterance.pitchMultiplier = pitchMultiplier ?? 1.0
            // 设置音量（默认 1.0）
            utterance.volume = volume ?? 1.0

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
