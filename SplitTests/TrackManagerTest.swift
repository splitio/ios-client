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
        var config = TrackManagerConfig(firstPushWindow: 100000, pushRate: 100000, queueSize: 100000, eventsPerPush: 200, maxHitsSizeInBytes: SplitClientConfig().maxEventsQueueMemorySizeInBytes)
        
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
        let config = TrackManagerConfig(firstPushWindow: 100000, pushRate: 100000, queueSize: 50, eventsPerPush: 200, maxHitsSizeInBytes: SplitClientConfig().maxEventsQueueMemorySizeInBytes)
        
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
