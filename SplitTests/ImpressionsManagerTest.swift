//
//  ImpressionsManagerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 05/08/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class ImpressionsManagerTest: XCTestCase {
    
    func testImpressionsFlush() {
        let config = ImpressionManagerConfig(pushRate: 200, impressionsPerPush: 100000)
        
        let restClient: RestClientImpressions = RestClientStub()
        let impressionsManager = DefaultImpressionsManager(dispatchGroup: nil, config: config, fileStorage: FileStorageStub(), restClient: restClient)
        for _ in 1...10 {
            impressionsManager.appendImpression(impression: createImpression(), splitName: "sample_feature")
        }
        impressionsManager.flush()
        let sentCount = (restClient as! RestClientStub).getSendImpressionsCount()
        
        XCTAssertEqual(1, sentCount)
    }
    
    private func createImpression()-> Impression {
        let impression: Impression = Impression()
        impression.keyName = "thekey"
        impression.bucketingKey = nil
        impression.label = "default rule"
        impression.changeNumber = 111111
        impression.treatment = "on"
        impression.time = Date().unixTimestampInMiliseconds()
        return impression
    }
    
}
