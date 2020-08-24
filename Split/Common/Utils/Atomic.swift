//
//  Atomic.swift
//  Split
//
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

final class AtomicInt {
    private let queue = DispatchQueue(label: "split_atomic_int")
    private var curValue: Int
    init(_ value: Int) {
        self.curValue = value
    }

    var value: Int {
            return queue.sync { self.curValue }
    }

    func getAndAdd(_ addValue: Int) -> Int {
        var oldValue: Int = 0
        queue.sync {
            oldValue = self.curValue
            self.curValue+=addValue
        }
        return oldValue
    }

    func mutate(_ transformation: (inout Int) -> Void) {
        queue.sync {
            transformation(&self.curValue)
        }
    }
}
