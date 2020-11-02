//
//  ImpressionsManagerStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 09/07/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

class ImpressionsManagerStub: ImpressionsManager {

    var startCalled = false
    var stopCalled = false
    var flushCalled = false

    var impressions: [String: Impression]
    
    init() {
        impressions = [String: Impression]()
    }
    
    func start() {
        startCalled = true
    }
    
    func stop() {
        stopCalled = true
    }
    
    func flush() {
        flushCalled = true
    }
    
    func appendImpression(impression: Impression, splitName: String) {
        impressions[splitName] = impression
    }
    
    func appendHitAndSendAll() {
    }
}
