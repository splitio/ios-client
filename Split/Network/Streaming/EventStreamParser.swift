//
//  EventStreamParser.swift
//  Split
//
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class EventStreamParser {
    static let kIdField = "id"
    static let kDataField = "data"
    static let kEventField = "event"
    private static let kKeepAliveEvent = "keepalive"
    private static let kFieldSeparator: Character = ":"
    private static let kKeepAliveToken = "\(kFieldSeparator)\(kKeepAliveEvent)"

    func parse(streamChunk: String) -> [String: String] {

        var messageValues = [String: String]()
        let messageLines = streamChunk.split(separator: "\n")
        for messageLine in messageLines {
            let trimmedLine = messageLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if Self.kKeepAliveToken == trimmedLine.lowercased() {
                messageValues[Self.kEventField] = Self.kKeepAliveEvent
                return messageValues
            }

            if trimmedLine.isEmpty() {
                return messageValues
            }

            guard let separatorIndex = trimmedLine.firstIndex(of: Self.kFieldSeparator) else {
                messageValues[trimmedLine] = ""
                return messageValues
            }

            if separatorIndex == trimmedLine.startIndex {
                return messageValues
            }

            let field = String(trimmedLine[..<separatorIndex])
            let value = String(trimmedLine[trimmedLine.index(after: separatorIndex)...])
            messageValues[field] = value
        }
        return messageValues
    }

    func isKeepAlive(values: [String: String]) -> Bool {
        return values.contains { eventType, value in
            return eventType == Self.kEventField &&
                value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == Self.kKeepAliveEvent
        }
    }

}
