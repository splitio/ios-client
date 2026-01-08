//
//  NotificationProcessorStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 01/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class SseNotificationProcessorStub: SseNotificationProcessor, @unchecked Sendable {
    var processCalled = false
    func process(_ notification: IncomingNotification) {
        processCalled = true
    }
}
