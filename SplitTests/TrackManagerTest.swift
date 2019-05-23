//
//  TrackManagerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 21/05/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class TrackManagerTest: XCTestCase {
    
    func testEventsFlushedWhenSizeLimitReached() {
        var config = TrackManagerConfig()
        config.firstPushWindow = 100000
        config.queueSize = 100000
        config.eventsPerPush = 200
        config.pushRate = 100000
        config.maxHitsSizeInBytes = SplitClientConfig().maxEventsQueueMemorySizeInBytes
        
        let restClient: RestClientTrackEvents = RestClientStub()
        let trackManager = TrackManager(dispatchGroup: nil, config: config, fileStorage: FileStorageStub(), restClient: restClient)
        for _ in 1...159 {
            trackManager.appendEvent(event: create32kbEvent())
        }
        
        let prevSendCount = (restClient as! RestClientStub).getSendTrackEventsCount()
        trackManager.appendEvent(event: create32kbEvent())
        let lastSendCount = (restClient as! RestClientStub).getSendTrackEventsCount()
        
        XCTAssertEqual(0, prevSendCount)
        XCTAssertEqual(1, lastSendCount)
        
    }
    
    func testEventsFlushedWhenCountLimitReached() {
        var config = TrackManagerConfig()
        config.firstPushWindow = 100000
        config.queueSize = 50
        config.eventsPerPush = 200
        config.pushRate = 100000
        config.maxHitsSizeInBytes = SplitClientConfig().maxEventsQueueMemorySizeInBytes
        
        let restClient: RestClientTrackEvents = RestClientStub()
        let trackManager = TrackManager(dispatchGroup: nil, config: config, fileStorage: FileStorageStub(), restClient: restClient)
        for _ in 1...49 {
            trackManager.appendEvent(event: create32kbEvent())
        }
        
        let prevSendCount = (restClient as! RestClientStub).getSendTrackEventsCount()
        trackManager.appendEvent(event: create32kbEvent())
        let lastSendCount = (restClient as! RestClientStub).getSendTrackEventsCount()
        
        XCTAssertEqual(0, prevSendCount)
        XCTAssertEqual(1, lastSendCount)
        
    }
    
    func create32kbEvent() -> EventDTO {
        let event = EventDTO(trafficType: "custom", eventType: "type")
        event.timestamp = 111111
        event.key = "validkey"
        event.sizeInBytes = 1024 * 32;
        return event;
    }
}
