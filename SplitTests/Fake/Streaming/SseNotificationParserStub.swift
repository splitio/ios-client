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
    var membershipsUpdateNotification: MembershipsUpdateNotification?
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

    func parseMembershipsUpdate(jsonString: String, type: NotificationType) throws -> MembershipsUpdateNotification {
        return membershipsUpdateNotification!
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

    var userKeyHash: String = ""
    func extractUserKeyHashFromChannel(channel: String) -> String? {
        return userKeyHash
    }
}
