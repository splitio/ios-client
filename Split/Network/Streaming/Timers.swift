//
//  Timers.swift
//  Split
//
//  Created by Javier L. Avrudsky on 14/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol SplitTimer {
}

enum StreamingTimer: SplitTimer {
    case authRecconect
    case sseReconnect
    case refresahAuthToken
    case appHostBgDisconnect
    case keepAlive
}

typealias TimerTriggerHandler = (SplitTimer) -> Void

protocol TimersManager {
    func add(timer: SplitTimer, delayInSeconds: Int)
    func triggerHandler(handler: TimerTriggerHandler)
}
