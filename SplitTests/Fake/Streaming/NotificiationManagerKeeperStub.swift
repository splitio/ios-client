//
//  NotificiationManagerKeeperStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 01/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class NotificationManagerKeeperStub: NotificationManagerKeeper {
    var handleIncomingPresenceEventCalled = false
    func handleIncomingPresenceEvent(notificiation: OccupancyNotification) {
        handleIncomingPresenceEventCalled = true
    }
}
