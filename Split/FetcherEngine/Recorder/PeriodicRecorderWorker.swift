//
//  PeriodicRecorder.swift
//  Split
//
//  Created by Javier Avrudsky on 02-Dic-2020
//
//

import Foundation

protocol PeriodicRecorderWorker {
    func start()
    func pause()
    func resume()
    func stop()
    func destroy()
}
//
class DefaultPeriodicRecorderWorker: PeriodicRecorderWorker {

    private let recorderWorker: RecorderWorker
    private var fetchTimer: PeriodicTimer
    private let fetchQueue = DispatchQueue.global()
    private var isPaused: Atomic<Bool> = Atomic(false)

    init(timer: PeriodicTimer,
         recorderWorker: RecorderWorker) {
        self.recorderWorker = recorderWorker
        self.fetchTimer = timer
        self.fetchTimer.handler { [weak self] in
            guard let self = self else {
                return
            }
            if self.isPaused.value {
                return
            }
            self.fetchQueue.async {
                self.sendToRemote()
            }
        }
    }

    func start() {
        startPeriodicRecording()
    }

    func pause() {
        isPaused.set(true)
    }

    func resume() {
        isPaused.set(false)
    }

    func stop() {
        stopPeriodicRecording()
    }

    func destroy() {
        fetchTimer.stop()
        fetchTimer.destroy()
    }

    private func startPeriodicRecording() {
        fetchTimer.trigger()
    }

    private func stopPeriodicRecording() {
        fetchTimer.stop()
    }

    func sendToRemote() {
        recorderWorker.flush()
    }
}
