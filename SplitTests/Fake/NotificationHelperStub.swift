//
//  NotificationHelperStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 06/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest   
@testable import Split

class NotificationHelperStub: NotificationHelper {
    var observers = [AppNotification: ObserverAction]()

    func addObserver(for notification: AppNotification, action: @escaping ObserverAction) {
        observers[notification] = action
    }

    func removeAllObservers() {
    }

    func trigger(notification: AppNotification) {
        observers[notification]?()
    }
}
