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
        let queue = DispatchQueue(label: "thread-utils", target: .global())
        let semaphore = DispatchSemaphore(value: 0)
        queue.asyncAfter(deadline: .now() + seconds) {
            semaphore.signal()
        }
        semaphore.wait()
    }

    // totalTaskCount: Total amount of task to run
    // minTaskPerThread: Minumum task amount to run per thread
    static func processCount(totalTaskCount: Int, minTaskPerThread: Int) -> Int {
        if minTaskPerThread == 0 {
            Logger.d("Min task per thread should be more that 0")
            return 1
        }

        // If task count is less than per thread
        // lets run all in one  thread only to avoid threading overhead
        let coreCount = ProcessInfo.processInfo.processorCount
        if totalTaskCount <= minTaskPerThread {
            return 1
        }

        // Let's compute thread count if using all means run less
        // tasks than minTaskPerThread
        let minTaskTotal = minTaskPerThread * coreCount
        if minTaskTotal > totalTaskCount {
            return coreCount - Int((minTaskTotal - totalTaskCount) / minTaskPerThread)
        }

        // Task execeds min amount per task.
        // Let's use all the cores
        Logger.v("Using all Cores to process splits: \(coreCount)")
        return coreCount
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
    private(set) var taskId: Int64
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

extension DispatchQueue {
    static var critical: DispatchQueue = {
        DispatchQueue(label: "split-critical", qos: .userInteractive, attributes: .concurrent)
    }()

    static var general: DispatchQueue = {
        DispatchQueue(label: "split-general", attributes: .concurrent)
    }()
}
