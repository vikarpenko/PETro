//
//  VoiceEngine.swift
//  PETro
//
//  Created by Діана Цісарук on 20.06.2026.
//
import Foundation
import AVFoundation


@MainActor
final class VoiceEngine {

    enum State {
        case idle
        case listening
        case processing
        case playingBack
    }

    private(set) var state: State = .idle

    var onPlaybackStart: (() -> Void)?
    var onPlaybackEnd: (() -> Void)?

    private let engine = AVAudioEngine()
    private var recordedBuffers: [AVAudioPCMBuffer] = []
    private var recordingFormat: AVAudioFormat?

    private var playerEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var pitchUnit: AVAudioUnitTimePitch?

    private let maxRecordingDuration: TimeInterval = 4.0
    private var recordingStartTime: Date?


    func requestMicPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }
    
    nonisolated func prepareAvSession() {
            Task.detached {
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
                try? session.setActive(true)
                _ = AVAudioEngine().inputNode
            }
        }


    func startListening() throws {
        guard state == .idle else { return }

//        let session = AVAudioSession.sharedInstance()
//        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
//        try session.setActive(true)

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        recordingFormat = format
        recordedBuffers.removeAll()

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            Task { @MainActor in
                self?.recordedBuffers.append(buffer)
            }
        }

        try engine.start()
        recordingStartTime = Date()
        state = .listening
    }

    var shouldAutoStop: Bool {
        guard let start = recordingStartTime else { return false }
        return Date().timeIntervalSince(start) >= maxRecordingDuration
    }

    var recordedDuration: TimeInterval {
        guard let format = recordingFormat, format.sampleRate > 0 else { return 0 }
        let totalFrames = recordedBuffers.reduce(0) { $0 + Int($1.frameLength) }
        return Double(totalFrames) / format.sampleRate
    }

    func stopListening() {
        guard state == .listening else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        state = .idle
    }

    func playBackAsParrot(pitchCents: Float = 700, rate: Float = 1.15) {
        guard !recordedBuffers.isEmpty, let format = recordingFormat else { return }
        state = .processing

        let renderEngine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = pitchCents
        pitch.rate = rate

        renderEngine.attach(player)
        renderEngine.attach(pitch)
        renderEngine.connect(player, to: pitch, format: format)
        renderEngine.connect(pitch, to: renderEngine.mainMixerNode, format: format)

        self.playerEngine = renderEngine
        self.playerNode = player
        self.pitchUnit = pitch

        do {
            try renderEngine.start()
        } catch {
            state = .idle
            return
        }

        for buffer in recordedBuffers {
            player.scheduleBuffer(buffer, completionHandler: nil)
        }

        let totalFrames = recordedBuffers.reduce(0) { $0 + Int($1.frameLength) }
        let duration = Double(totalFrames) / format.sampleRate / Double(rate)

        state = .playingBack
        onPlaybackStart?()
        player.play()

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            self?.finishPlayback()
        }
    }

    private func finishPlayback() {
        playerNode?.stop()
        playerEngine?.stop()
        playerEngine = nil
        playerNode = nil
        pitchUnit = nil
        state = .idle
        onPlaybackEnd?()
    }

    func cancel() {
        stopListening()
        finishPlayback()
        recordedBuffers.removeAll()
    }
}
