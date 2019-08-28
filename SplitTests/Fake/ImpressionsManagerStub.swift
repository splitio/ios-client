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
    var impressions: [String: Impression]
    
    init() {
        impressions = [String: Impression]()
    }
    
    func start() {
    }
    
    func stop() {
    }
    
    func flush() {
    }
    
    func appendImpression(impression: Impression, splitName: String) {
        impressions[splitName] = impression
    }
    
    func appendHitAndSendAll() {
    }
}
