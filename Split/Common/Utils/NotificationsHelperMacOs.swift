//
//  NNotificationsWrapper.swift
//  Split
//
//  Created by Javier on 07/11/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation
import AppKit

typealias ObserverAction = () -> Void

enum AppNotification: String {
    case didEnterBackground
    case didBecomeActive
}

/// ** NotificationHelper **
/// This class is a wrapper to handle some app notifications to avoid the
/// boilerplate code involved when registering to observe native notifications.
/// The main goal is to replace @obj functions based handler with Swift closures,
/// that way the code becomes streight and simple.

protocol NotificationHelper {
    func addObserver(for notification: AppNotification, action: @escaping ObserverAction)
    func removeAllObservers()
}

class DefaultNotificationHelper: NotificationHelper {

    private let queue = DispatchQueue(label: UUID.init().uuidString, attributes: .concurrent)
    private var actions = [String: [ObserverAction]]()

    static let instance: DefaultNotificationHelper = {
        return DefaultNotificationHelper()
    }()

    private init() {
        //subscribe()
    }

    deinit {
        //unsubscribe()
    }

    func addObserver(for notification: AppNotification, action: @escaping ObserverAction) {
        queue.async(flags: .barrier) {
            if self.actions[notification.rawValue] == nil {
                self.actions[notification.rawValue] = [ObserverAction]()
            }
            self.actions[notification.rawValue]?.append(action)
        }
    }

    private func subscribe() {
        #if swift(>=4.2)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: NSApplication.didResignActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: NSApplication.didBecomeActiveNotification,
                                               object: nil)
        #else
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: .didResignActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: .applicationDidBecomeActive,
                                               object: nil)
        #endif
    }

    private func unsubscribe()  {
        #if swift(>=4.2)
        NotificationCenter.default.removeObserver(self, name: NSApplication.didResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSApplication.didBecomeActiveNotification, object: nil)
        #else
        NotificationCenter.default.removeObserver(self, name: .didResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didBecomeActiveNotification, object: nil)
        #endif
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

    @objc private func applicationDidEnterBackground() {
        executeActions(for: AppNotification.didEnterBackground)
    }

    @objc private func applicationDidBecomeActive() {
        executeActions(for: AppNotification.didBecomeActive)
    }

    func removeAllObservers() {
        queue.sync {
           actions.removeAll()
        }
    }
}
