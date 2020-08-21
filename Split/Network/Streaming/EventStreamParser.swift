//
//  EventStreamParser.swift
//  Split
//
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class EventStreamParser {
    private static let kEventField = "event"
    private static let kKeepAliveEvent = "keepalive"
    private static let kFieldSeparator: Character = ":"
    private static let kKeepAliveToken = "\(kFieldSeparator)\(kKeepAliveEvent)"

    func parseLineAndAppendValue(streamLine: String, messageValues: SyncDictionarySingleWrapper<String, String>) -> Bool {

        let trimmedLine = streamLine.trimmingCharacters(in: .whitespacesAndNewlines)

        if Self.kKeepAliveToken == trimmedLine {
            messageValues.setValue(Self.kKeepAliveEvent, forKey: Self.kEventField)
            return true
        }

        if trimmedLine.isEmpty(), messageValues.count == 0 {
            return false
        }

        if trimmedLine.isEmpty() {
            return true
        }

        guard let separatorIndex = trimmedLine.firstIndex(of: Self.kFieldSeparator) else {
            messageValues.setValue("", forKey: trimmedLine)
            return false
        }

        if separatorIndex == trimmedLine.startIndex {
            return false
        }

        let field = String(trimmedLine[..<separatorIndex])
        let value = String(trimmedLine[trimmedLine.index(after: separatorIndex)...])
        messageValues.setValue(value, forKey: field)
        return false
    }

    func isKeepAlive(values: [String: String]) -> Bool {
        return values.contains { eventType, value in
            return eventType == Self.kEventField && value == Self.kKeepAliveEvent
        }
    }

}
