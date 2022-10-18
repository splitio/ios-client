//
//  NNotificationsWrapper.swift
//  Split
//
//  Created by Javier on 07/11/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

#if canImport(WatchKit)
import WatchKit
#endif

#if canImport(TVUIKit)
import TVUIKit
#endif

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

#if os(iOS) || os(tvOS)

#if swift(>=4.2)
    static let didEnterBgNotification = UIApplication.didEnterBackgroundNotification
    static let didBecomeActiveNotification = UIApplication.didBecomeActiveNotification
#else
    static let didEnterBgNotification = NSNotification.Name.UIApplicationDidEnterBackground
    static let didBecomeActiveNotification = NSNotification.Name.UIApplicationDidBecomeActive
#endif

#elseif os(macOS)
    static let didEnterBgNotification = NSApplication.didResignActiveNotification
    static let didBecomeActiveNotification = NSApplication.didBecomeActiveNotification

#elseif os(watchOS)
    static let didEnterBgNotification = WKExtension.applicationDidEnterBackgroundNotification
    static let didBecomeActiveNotification = WKExtension.applicationDidBecomeActiveNotification

#endif

    static let instance: DefaultNotificationHelper = {
        return DefaultNotificationHelper()
    }()

    private init() {
        subscribe()
    }

    deinit {
        unsubscribe()
    }

    func addObserver(for notification: AppNotification, action: @escaping ObserverAction) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            if self.actions[notification.rawValue] == nil {
                self.actions[notification.rawValue] = [ObserverAction]()
            }
            self.actions[notification.rawValue]?.append(action)
        }
    }

    private func subscribe() {

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: Self.didEnterBgNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: Self.didBecomeActiveNotification,
                                               object: nil)
    }

    private func unsubscribe() {
        NotificationCenter.default.removeObserver(self, name: Self.didEnterBgNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Self.didBecomeActiveNotification, object: nil)
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
        Logger.d("Split host app is inactive")
    }

    @objc private func applicationDidBecomeActive() {
        executeActions(for: AppNotification.didBecomeActive)
        Logger.d("Split host app become active")
    }

    func removeAllObservers() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.actions.removeAll()
        }
    }
}
