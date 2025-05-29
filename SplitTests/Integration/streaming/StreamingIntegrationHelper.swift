//
//  StreamingIntegrationHelper.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 15/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class StreamingIntegrationHelper {
    static func ruleBasedSegmentUpdateMessage(
        timestamp: Int = 1000,
        changeNumber: Int = 1000,
        segmentData: String) -> String {
        return """
        id:cf74eb42-f687-48e4-ad18-af2125110aac
        event:message
        data:{"id":"VSEQrcq9D8:0:0","clientId":"NDEzMTY5Mzg0MA==:MjU4MzkwNDA2NA==","timestamp":$TIMESTAMP$,"encoding":"json","channel":"MzM5Njc0ODcyNg==_MTExMzgwNjgx_ruleBasedSegments","data":"{\"type\":\"RULE_BASED_SEGMENT_UPDATE\",\"changeNumber\":$CHANGE_NUMBER$,\"data\":$SEGMENT_DATA$}"}
        """.replacingOccurrences(of: "$TIMESTAMP$", with: "\(timestamp)")
            .replacingOccurrences(of: "$CHANGE_NUMBER$", with: "\(changeNumber)")
            .replacingOccurrences(of: "$SEGMENT_DATA$", with: segmentData)
    }

    static func splitUpdateMessage(timestamp: Int = 1000, changeNumber: Int = 1000) -> String {
        return """
        id:cf74eb42-f687-48e4-ad18-af2125110aac
        event:message
        data:{"id":"VSEQrcq9D8:0:0","clientId":"NDEzMTY5Mzg0MA==:MjU4MzkwNDA2NA==","timestamp":$TIMESTAMP$,"encoding":"json","channel":"MzM5Njc0ODcyNg==_MTExMzgwNjgx_splits","data":"{\\"type\\":\\"SPLIT_UPDATE\\",\\"changeNumber\\":$CHANGE_NUMBER$}"}
        """.replacingOccurrences(of: "$TIMESTAMP$", with: "\(timestamp)")
            .replacingOccurrences(of: "$CHANGE_NUMBER$", with: "\(changeNumber)")
    }

    static func splitKillMessagge(
        splitName: String,
        defaultTreatment: String,
        timestamp: Int = 1000,
        changeNumber: Int = 1000) -> String {
        return """
        id:cf74eb42-f687-48e4-ad18-af2125110aac
        event:message
        data:{"id":"VSEQrcq9D8:0:0","clientId":"NDEzMTY5Mzg0MA==:MjU4MzkwNDA2NA==","timestamp":$TIMESTAMP$,"encoding":"json","channel":"MzM5Njc0ODcyNg==_MTExMzgwNjgx_splits","data":"{\\"type\\":\\"SPLIT_KILL\\",\\"changeNumber\\":$CHANGE_NUMBER$,\\"splitName\\":\\"$SPLIT_NAME$\\",\\"defaultTreatment\\":\\"$DEFAULT_TREATMENT$\\"}"}
        """.replacingOccurrences(of: "$TIMESTAMP$", with: "\(timestamp)")
            .replacingOccurrences(of: "$CHANGE_NUMBER$", with: "\(changeNumber)")
            .replacingOccurrences(of: "$SPLIT_NAME$", with: "\(splitName)")
            .replacingOccurrences(of: "$DEFAULT_TREATMENT$", with: "\(defaultTreatment)")
    }

//    static func mySegmentNoPayloadMessage(timestamp: Int) -> String {
//        return """
//        id:cf74eb42-f687-48e4-ad18-af2125110aac
//        event:message
//        data:{"id":"VSEQrcq9D8:0:0","clientId":"NDEzMTY5Mzg0MA==:MjU4MzkwNDA2NA==","timestamp":$TIMESTAMP$,"encoding":"json","channel":"MzM5Njc0ODcyNg==_MTExMzgwNjgx_MjAwNjI0Nzg3NQ==_mySegments","data":"{\\"type\\":\\"MY_SEGMENTS_UPDATE\\",\\"changeNumber\\":2000, \\"includesPayload\\":false}"}
//        """.replacingOccurrences(of: "$TIMESTAMP$", with: "\(timestamp)")
//    }
//
//    static func mySegmentWithPayloadMessage(timestamp: Int, segment: String) -> String {
//        return """
//        id:cf74eb42-f687-48e4-ad18-af2125110aac
//        event:message
//        data:{"id":"VSEQrcq9D8:0:0","clientId":"NDEzMTY5Mzg0MA==:MjU4MzkwNDA2NA==","timestamp":$TIMESTAMP$,"encoding":"json","channel":"MzM5Njc0ODcyNg==_MTExMzgwNjgx_MjAwNjI0Nzg3NQ==_mySegments","data":"{\\"type\\":\\"MY_SEGMENTS_UPDATE\\",\\"changeNumber\\":2000, \\"includesPayload\\":true, \\"segmentList\\":[\\"$SEGMENT$\\"]}"}
//        """.replacingOccurrences(of: "$TIMESTAMP$", with: "\(timestamp)")
//        .replacingOccurrences(of: "$SEGMENT$", with: "\(segment)")
//    }

    static func occupancyMessage(timestamp: Int, publishers: Int, channel: String) -> String {
        return """
        id:cf74eb42-f687-48e4-ad18-af2125110aac
        event:message
        data:{"id":"VSEQrcq9D8:0:0","clientId":"NDEzMTY5Mzg0MA==:MjU4MzkwNDA2NA==","timestamp":$TIMESTAMP$,"encoding":"json","channel":"[?occupancy=metrics.publishers]$CHANNEL$", "name":"[meta]occupancy", "data":"{\\"metrics\\":{\\"publishers\\":$PUBLISHERS$}}"}
        """.replacingOccurrences(of: "$TIMESTAMP$", with: "\(timestamp)")
            .replacingOccurrences(of: "$CHANNEL$", with: "\(channel)")
            .replacingOccurrences(of: "$PUBLISHERS$", with: "\(publishers)")
    }

    static func controlMessage(timestamp: Int, controlType: String) -> String {
        return """
        id:cf74eb42-f687-48e4-ad18-af2125110aac
        event:message
        data:{ "id": "Y1XJoAm7No:0:0",  "clientId": "EORI49J_FSJKA2",  "timestamp": $TIMESTAMP$,  "encoding": "json",  "channel": "control_pri",  "data": "{\\"type\\":\\"CONTROL\\",\\"controlType\\":\\"$CONTROL_TYPE$\\"}"}
        """.replacingOccurrences(of: "$TIMESTAMP$", with: "\(timestamp)")
            .replacingOccurrences(of: "$CONTROL_TYPE$", with: "\(controlType)")
    }
}
