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
    private let mySegmentsUpdateWorker: SegmentsUpdateWorker
    private let myLargeSegmentsUpdateWorker: SegmentsUpdateWorker
    private let splitKillWorker: SplitKillWorker

    init(
        notificationParser: SseNotificationParser,
        splitsUpdateWorker: SplitsUpdateWorker,
        splitKillWorker: SplitKillWorker,
        mySegmentsUpdateWorker: SegmentsUpdateWorker,
        myLargeSegmentsUpdateWorker: SegmentsUpdateWorker) {
        self.sseNotificationParser = notificationParser
        self.splitsUpdateWorker = splitsUpdateWorker
        self.mySegmentsUpdateWorker = mySegmentsUpdateWorker
        self.splitKillWorker = splitKillWorker
        self.myLargeSegmentsUpdateWorker = myLargeSegmentsUpdateWorker
    }

    func process(_ notification: IncomingNotification) {
        Logger.d("Received notification \(notification.type)")
        switch notification.type {
        case .splitUpdate:
            processTargetingRuleUpdate(notification)
        case .ruleBasedSegmentUpdate:
            processTargetingRuleUpdate(notification)
        case .mySegmentsUpdate:
            processSegmentsUpdate(notification, updateWorker: mySegmentsUpdateWorker)
        case .myLargeSegmentsUpdate:
            processSegmentsUpdate(notification, updateWorker: myLargeSegmentsUpdateWorker)
        case .splitKill:
            processSplitKill(notification)
        default:
            Logger.e("Unknown notification arrived: \(notification.jsonData ?? "null")")
        }
    }

    private func processTargetingRuleUpdate(_ notification: IncomingNotification) {
        if let jsonData = notification.jsonData {
            do {
                try splitsUpdateWorker.process(
                    notification:
                    sseNotificationParser.parseTargetingRuleNotification(jsonString: jsonData, type: notification.type))
            } catch {
                Logger.e("Error while parsing targeting rule update notification: \(error.localizedDescription)")
            }
        }
    }

    private func processSegmentsUpdate(_ notification: IncomingNotification, updateWorker: SegmentsUpdateWorker) {
        if let jsonData = notification.jsonData {
            do {
                try updateWorker.process(
                    notification: sseNotificationParser.parseMembershipsUpdate(
                        jsonString: jsonData,
                        type: notification.type))
            } catch {
                Logger.e(
                    "Error while parsing \(notification.type) update notification:" +
                        " \(error.localizedDescription)")
            }
        }
    }

    private func processSplitKill(_ notification: IncomingNotification) {
        if let jsonData = notification.jsonData {
            do {
                try splitKillWorker.process(
                    notification:
                    sseNotificationParser.parseSplitKill(jsonString: jsonData))
            } catch {
                Logger.e("Error while parsing split kill notification: \(error.localizedDescription)")
            }
        }
    }
}
