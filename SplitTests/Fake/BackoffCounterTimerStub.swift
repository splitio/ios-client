//
//  BackoffCounterTimerStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 20/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class BackoffCounterTimerStub: BackoffCounterTimer {
    func schedule(handler: @escaping () -> Void) {

    }

    func cancel() {

    }
}
