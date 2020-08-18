//
//  Timers.swift
//  Split
//
//  Created by Javier L. Avrudsky on 14/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

enum TimerName {
    case authRecconect
    case sseReconnect
    case refresahAuthToken
    case appHostBgDisconnect
    case keepAlive
}

protocol TimersManager {
    func add(timer: TimerName, delayInSeconds: Int)
    func cancel(timer: TimerName)
    func triggerHandler(handler: (TimerName) -> Void)
}

