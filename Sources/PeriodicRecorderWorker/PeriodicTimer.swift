//  PeriodicTimer
//  Copyright © 2020 Split. All rights reserved.

import Foundation

public protocol PeriodicTimer: Sendable {
    func trigger()
    func stop()
    func destroy()
    func handler(_ handler: @escaping () -> Void)
}

public final class DefaultPeriodicTimer: PeriodicTimer, @unchecked Sendable {

    private let deadLineInSecs: Int
    private let intervalInSecs: Int
    private var fetchTimer: DispatchSourceTimer
    private var isRunning: Bool = false
    private let lock = NSLock()
    private let queue: DispatchQueue

    public init(deadline deadlineInSecs: Int, interval intervalInSecs: Int) {
        self.deadLineInSecs = deadlineInSecs
        self.intervalInSecs = intervalInSecs
        self.queue = DispatchQueue(label: "split-periodic-timer", attributes: .concurrent)
        fetchTimer = DispatchSource.makeTimerSource(queue: queue)
        self.fetchTimer.resume()
    }

    public convenience init(interval intervalInSecs: Int) {
        self.init(deadline: 0, interval: intervalInSecs)
    }

    public func trigger() {
        lock.lock()
        let wasRunning = isRunning
        isRunning = true
        lock.unlock()
        
        if !wasRunning {
            fetchTimer.schedule(deadline: .now() + .seconds(deadLineInSecs),
                                repeating: .seconds(intervalInSecs))
        }
    }

    public func stop() { // Not suspending the timer to avoid crashes
        lock.lock()
        isRunning = false
        lock.unlock()
    }

    public func destroy() {
        fetchTimer.cancel()
    }

    public func handler(_ handler: @escaping () -> Void) {
        let action = { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            let running = self.isRunning
            self.lock.unlock()
            if running {
                handler()
            }
        }
        fetchTimer.setEventHandler(handler: action)
    }
}
