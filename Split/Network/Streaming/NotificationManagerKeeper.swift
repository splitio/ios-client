//
//  NotificationManagerKeeper.swift
//  Split
//
//  Created by Javier L. Avrudsky on 01/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol NotificationManagerKeeper {
    func handleIncomingPresenceEvent(notificiation: OccupancyNotification)
}
