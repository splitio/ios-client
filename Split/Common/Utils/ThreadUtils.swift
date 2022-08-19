//
//  ThreadUtils.swift
//  Split
//
//  Created by Javier L. Avrudsky on 14/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class ThreadUtils {
    static func delay(seconds: Double) {
        // Using this method to avoid blocking the
        // thread using sleep
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().asyncAfter(deadline: .now() + seconds) {
            semaphore.signal()
        }
        semaphore.wait()
    }
}

class CancellableTask {
    typealias Work = () -> Void

    private (set) var taskId: Int64
    private(set) var isCancelled = false
    private(set) var delay: Double
    let work: Work

    init(delay: Int64, _ work: @escaping Work) {
        self.taskId = Date().unixTimestampInMiliseconds()
        self.work = work
        self.delay = Double(delay)
    }
    func cancel() {
        isCancelled = true
    }
}

struct TaskExecutor {
    typealias Work = () -> Void

    func run(_ task: CancellableTask) {
        DispatchQueue.global().asyncAfter(deadline: .now() + task.delay) {
            if !task.isCancelled {
                task.work()
            }
        }
    }
}
