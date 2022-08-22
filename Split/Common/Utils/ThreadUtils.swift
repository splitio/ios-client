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

protocol CancellableTask {
    typealias Work = () -> Void
    var taskId: Int64 { get }
    var isCancelled: Bool { get }
    var delay: Double { get }
    var work: Work { get }
    func cancel()
}

class DefaultTask: CancellableTask {

    private (set) var taskId: Int64
    private(set) var isCancelled = false
    private(set) var delay: Double
    private(set) var work: Work

    init(delay: Int64, work: @escaping Work) {
        self.taskId = Date().unixTimestampInMiliseconds()
        self.delay = Double(delay)
        self.work = work
    }
    func cancel() {
        isCancelled = true
    }
}

struct TaskExecutor {
    func run(_ task: CancellableTask) {
        DispatchQueue.global().asyncAfter(deadline: .now() + task.delay) {
            if !task.isCancelled {
                task.work()
            }
        }
    }
}
