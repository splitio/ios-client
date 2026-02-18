//  PeriodicRecorderWorker
//  Created by Javier Avrudsky on 02-Dic-2020.
//  Copyright © 2020 Split. All rights reserved.

import Foundation

public protocol RecorderWorker: Sendable {
    func flush()
}

public protocol PeriodicRecorderWorker: Sendable {
    func start()
    func pause()
    func resume()
    func stop()
    func destroy()
}

public final class DefaultPeriodicRecorderWorker: PeriodicRecorderWorker, @unchecked Sendable {

    private let recorderWorker: RecorderWorker
    private var fetchTimer: PeriodicTimer
    private let fetchQueue: DispatchQueue
    private var isPaused: Bool = false
    private let lock = NSLock()

    public init(timer: PeriodicTimer, recorderWorker: RecorderWorker) {
        self.recorderWorker = recorderWorker
        self.fetchTimer = timer
        self.fetchQueue = DispatchQueue(label: "split-periodic-recorder", attributes: .concurrent)
        self.fetchTimer.handler { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            let paused = self.isPaused
            self.lock.unlock()
            if paused { return }
            self.fetchQueue.async {
                self.sendToRemote()
            }
        }
    }

    public func start() {
        fetchTimer.trigger()
    }

    public func pause() {
        lock.lock()
        isPaused = true
        lock.unlock()
    }

    public func resume() {
        lock.lock()
        isPaused = false
        lock.unlock()
    }

    public func stop() {
        fetchTimer.stop()
    }

    public func destroy() {
        fetchTimer.stop()
        fetchTimer.destroy()
    }

    private func sendToRemote() {
        recorderWorker.flush()
    }
}
