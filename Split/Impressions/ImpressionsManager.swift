//
//  ImpressionsManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/07/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

protocol ImpressionsManager {
    func start()
    func stop()
    func flush()
    func appendImpression(impression: Impression, splitName: String)
    func appendHitAndSendAll()
}
