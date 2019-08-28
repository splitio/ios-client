//
//  TrackManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 01/08/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

protocol TrackManager {
    func start()
    func stop()
    func flush()
    func appendEvent(event: EventDTO)
}
