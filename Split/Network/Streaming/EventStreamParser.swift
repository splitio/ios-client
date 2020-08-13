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

    func parseLineAndAppendValue(streamLine: String, messageValues: inout [String: String]) -> Bool {

        let trimmedLine = streamLine.trimmingCharacters(in: .whitespacesAndNewlines)

        if Self.kKeepAliveToken == trimmedLine {
            messageValues[Self.kEventField] = Self.kKeepAliveEvent
            return true
        }

        if trimmedLine.isEmpty(), messageValues.count == 0 {
            return false
        }

        if trimmedLine.isEmpty() {
            return true
        }

        guard let separatorIndex = trimmedLine.firstIndex(of: Self.kFieldSeparator) else {
             messageValues[trimmedLine] = ""
            return false
        }

        if separatorIndex == trimmedLine.startIndex {
            return false
        }

        let field = String(trimmedLine[..<separatorIndex])
        messageValues[field] = String(trimmedLine[trimmedLine.index(after: separatorIndex)...])
        return false
    }

    /**
     * This parsing implementation is based in the folowing specification:
     * https://www.w3.org/TR/2009/WD-eventsource-20090421/#references
     * Bulletpoint 7 Interpreting an event stream
     *
     * @param streamLine:    The line from the stream to be parsed
     * @param messageValues: A map where the field, value pair is should added be added
     *                       if the line contains any.
     * @return Returns true if a blank line meaning the final of an event if found.
     */
//    @VisibleForTesting
//    public boolean parseLineAndAppendValue(String streamLine, Map<String, String> messageValues) {
//
//        if (streamLine == null) {
//            return false;
//        }
//
//        String trimmedLine = streamLine.trim();
//
//        if (KEEP_ALIVE_TOKEN.equals(trimmedLine)) {
//            messageValues.put(EVENT_FIELD, KEEP_ALIVE_EVENT);
//            return true;
//        }
//
//        if (trimmedLine.isEmpty() && messageValues.size() == 0) {
//            return false;
//        }
//
//        if (trimmedLine.isEmpty()) {
//            return true;
//        }
//
//        int separatorIndex = trimmedLine.indexOf(FIELD_SEPARATOR);
//
//        if (separatorIndex == 0) {
//            return false;
//        }
//
//        if (separatorIndex > -1) {
//            String field = trimmedLine.substring(0, separatorIndex).trim();
//            String value = "";
//            if (separatorIndex < trimmedLine.length() - 1) {
//                value = trimmedLine.substring(separatorIndex + 1, trimmedLine.length()).trim();
//            }
//            messageValues.put(field, value);
//        } else {
//            messageValues.put(trimmedLine.trim(), "");
//        }
//        return false;
//    }
//
//    public boolean isKeepAlive(Map<String, String> values) {
//        return KEEP_ALIVE_EVENT.equals(values.get(EVENT_FIELD));
//    }

}
