import Foundation
import Speech
import AVFoundation

#if os(iOS)
@Observable
@MainActor
final class SpeechService {
    var isRecording = false
    var transcribedText = ""
    var isAuthorized = false
    var errorMessage: String?

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                self?.isAuthorized = (status == .authorized)
            }
        }
    }

    func startRecording() {
        guard !isRecording else { return }
        guard speechRecognizer?.isAvailable == true else {
            errorMessage = "Speech recognition unavailable"
            return
        }

        // Reset
        stopRecording()
        transcribedText = ""
        errorMessage = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session failed"
            return
        }

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            errorMessage = "Audio engine failed"
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let result {
                    self.transcribedText = result.bestTranscription.formattedString
                }

                if error != nil || result?.isFinal == true {
                    self.cleanupEngine()
                }
            }
        }

        self.audioEngine = engine
        self.recognitionRequest = request
        isRecording = true
    }

    func stopRecording() {
        guard isRecording else { return }
        cleanupEngine()
    }

    private func cleanupEngine() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
#endif
