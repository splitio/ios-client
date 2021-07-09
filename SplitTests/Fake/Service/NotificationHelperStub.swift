//
//  NotificationManagerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 07-Jul-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split

class NotificationHelperStub: NotificationHelper {
    private let queue = DispatchQueue(label: UUID.init().uuidString, attributes: .concurrent)
    private var actions = [String: [ObserverAction]]()

    func addObserver(for notification: AppNotification, action: @escaping ObserverAction) {
        queue.async(flags: .barrier) {
            if self.actions[notification.rawValue] == nil {
                self.actions[notification.rawValue] = [ObserverAction]()
            }
            self.actions[notification.rawValue]?.append(action)
        }
    }

    private func executeActions(for notification: AppNotification) {
        var actions: [ObserverAction]?
        queue.sync {
            actions = self.actions[notification.rawValue]
        }
        if let actions =  actions {
            for action in actions {
                action()
            }
        }
    }

    func simulateApplicationDidEnterBackground() {
        executeActions(for: AppNotification.didEnterBackground)
    }

    func simulateApplicationDidBecomeActive() {
        executeActions(for: AppNotification.didBecomeActive)
    }

    func removeAllObservers() {
        queue.sync {
            actions.removeAll()
        }
    }

}
