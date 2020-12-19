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
