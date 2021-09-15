//
//  SseNotificationParserStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 25/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class SseNotificationParserStub: SseNotificationParser {

    var incomingNotification: IncomingNotification?
    var splitsUpdateNotification: SplitsUpdateNotification?
    var splitKillNotification: SplitKillNotification?
    var mySegmentsUpdateNotification: MySegmentsUpdateNotification?
    var mySegmentsUpdateV2Notification: MySegmentsUpdateV2Notification?
    var occupancyNotification: OccupancyNotification?
    var controlNotification: ControlNotification?
    var sseErrorNotification: StreamingError?
    var isError = false


    func parseIncoming(jsonString: String) -> IncomingNotification? {
        return incomingNotification
    }

    func parseSplitUpdate(jsonString: String) throws -> SplitsUpdateNotification {
        return splitsUpdateNotification!
    }

    func parseSplitKill(jsonString: String) throws -> SplitKillNotification {
        return splitKillNotification!
    }

    func parseMySegmentUpdate(jsonString: String) throws -> MySegmentsUpdateNotification {
        return mySegmentsUpdateNotification!
    }

    func parseMySegmentUpdateV2(jsonString: String) throws -> MySegmentsUpdateV2Notification {
        return mySegmentsUpdateV2Notification!
    }

    func parseOccupancy(jsonString: String, timestamp: Int64, channel: String) throws -> OccupancyNotification {
        return occupancyNotification!
    }

    func parseControl(jsonString: String) throws -> ControlNotification {
        return controlNotification!
    }

    func parseSseError(jsonString: String) throws -> StreamingError {
        return sseErrorNotification!
    }

    func isError(event: [String : String]) -> Bool {
        return isError
    }
}
