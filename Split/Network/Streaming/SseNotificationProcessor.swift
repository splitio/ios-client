//
//  SseNotificationProcessor.swift
//  Split
//
//  Created by Javier L. Avrudsky on 24/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol SseNotificationProcessor {
    func process(_ notification: IncomingNotification)
}

class DefaultSseNotificationProcessor: SseNotificationProcessor {

    private let sseNotificationParser: SseNotificationParser
    private let splitsUpdateWorker: SplitsUpdateWorker
    private let mySegmentsUpdateWorker: MySegmentsUpdateWorker
    private let mySegmentsUpdateV2Worker: MySegmentsUpdateV2Worker
    private let splitKillWorker: SplitKillWorker

    init (notificationParser: SseNotificationParser,
          splitsUpdateWorker: SplitsUpdateWorker,
          splitKillWorker: SplitKillWorker,
          mySegmentsUpdateWorker: MySegmentsUpdateWorker,
          mySegmentsUpdateV2Worker: MySegmentsUpdateV2Worker) {

        self.sseNotificationParser = notificationParser
        self.splitsUpdateWorker = splitsUpdateWorker
        self.mySegmentsUpdateWorker = mySegmentsUpdateWorker
        self.splitKillWorker = splitKillWorker
        self.mySegmentsUpdateV2Worker = mySegmentsUpdateV2Worker
    }

    func process(_ notification: IncomingNotification) {
        Logger.d("Received notification \(notification.type)")
        switch notification.type {
        case .splitUpdate:
            processSplitsUpdate(notification)
        case .mySegmentsUpdate:
            processMySegmentsUpdate(notification)
        case .mySegmentsUpdateV2:
            processMySegmentsUpdateV2(notification)
        case .splitKill:
            processSplitKill(notification)
        default:
            Logger.e("Unknown notification arrived: \(notification.jsonData ?? "null" )")
        }
    }

    private func processSplitsUpdate(_ notification: IncomingNotification) {
        if let jsonData = notification.jsonData {
            do {
                try splitsUpdateWorker.process(notification:
                    sseNotificationParser.parseSplitUpdate(jsonString: jsonData))
            } catch {
                Logger.e("Error while parsing split update notification: \(error.localizedDescription)")
            }
        }
    }

    private func processMySegmentsUpdateV2(_ notification: IncomingNotification) {

        if let jsonData = notification.jsonData {
            do {
                try mySegmentsUpdateV2Worker.process(
                    notification: sseNotificationParser.parseMySegmentUpdateV2(jsonString: jsonData)
                )
            } catch {
                Logger.e("Error while parsing my segments update notification: \(error.localizedDescription)")
            }
        }
    }

    private func processSplitKill(_ notification: IncomingNotification) {
        if let jsonData = notification.jsonData {
            do {
                try splitKillWorker.process(notification:
                    sseNotificationParser.parseSplitKill(jsonString: jsonData))
            } catch {
                Logger.e("Error while parsing split kill notification: \(error.localizedDescription)")
            }
        }
    }

    private func processMySegmentsUpdate(_ notification: IncomingNotification) {
        if let jsonData = notification.jsonData {
            do {
                let parsed = try sseNotificationParser.parseMySegmentUpdate(jsonString: jsonData,
                                                                            channel: notification.channel ?? "")
                try mySegmentsUpdateWorker.process(notification: parsed)
            } catch {
                Logger.e("Error while processing my segments update notification: \(error.localizedDescription)")
            }
        }
    }
}
