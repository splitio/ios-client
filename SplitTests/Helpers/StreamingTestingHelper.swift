//
//  StreamingTestingHelper.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 17/10/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

class StreamingTestingHelper {
    private var pushSplitsTemplate: String!
    private var pushMySegmentsTemplate: String!
    private let kDataField = "[NOTIFICATION_DATA]"
    var streamingBinding: TestStreamResponseBinding?

    init() {
        loadSplitsNotificationTemplate()
        loadMySegmentsNotificationTemplate()
    }

    private func loadSplitsNotificationTemplate() {
        if let template = FileHelper.readDataFromFile(sourceClass: self, name: "push_msg-splits_updV2", type: "txt") {
            pushSplitsTemplate = template
        }
    }

    private func loadMySegmentsNotificationTemplate() {
        if let template = FileHelper.readDataFromFile(sourceClass: self, name: "push_msg-segment_updV2", type: "txt") {
            pushMySegmentsTemplate = template
        }
    }

    func pushSplitsMessage(_ text: String) {
        pushMessage(text, template: pushSplitsTemplate)
    }

    func pushSMySegmentsMessage(_ text: String) {
        pushMessage(text, template: pushMySegmentsTemplate)
    }

    func pushKeepalive() {
        streamingBinding?.push(message: TestingData.keepalive)
    }

    private func pushMessage(_ text: String, template: String) {
        var msg = text.replacingOccurrences(of: "\n", with: " ")
        msg = template.replacingOccurrences(of: kDataField, with: msg)
        if let strBin = streamingBinding {
            print("Streaming helper: pushing message")
            strBin.push(message: msg)
        } else {
            print("Streaming helper: binding is null")
        }
    }
}
