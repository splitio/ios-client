//
//  EnvironmentTargetManager.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/2/18.
//

import Foundation

class EnvironmentTargetManager {
    private let kDefaultSdkBaseUrl = "https://sdk.split.io/api"
    private let kDefaultEventsBaseUrl = "https://events.split.io/api"

    var sdkBaseUrl: URL
    var eventsBaseURL: URL

    var eventsEndpoint: String {
        get {
            return eventsBaseURL.absoluteString
        }
        set {
            self.eventsBaseURL = URL(string: newValue) ?? URL(string: kDefaultEventsBaseUrl)!
        }
    }

    var sdkEndpoint: String {
        get {
            return sdkBaseUrl.absoluteString
        }
        set {
            self.sdkBaseUrl = URL(string: newValue) ?? URL(string: kDefaultSdkBaseUrl)!
        }
    }

    static let shared: EnvironmentTargetManager = {
        let instance = EnvironmentTargetManager()
        return instance
    }()

    //Guarantee singleton instance
    private init() {
        sdkBaseUrl = URL(string: kDefaultSdkBaseUrl)!
        eventsBaseURL = URL(string: kDefaultEventsBaseUrl)!
    }

    public static func getSplitChanges(since: Int64) -> Target {
        return DynamicTarget(shared.sdkBaseUrl,
                             shared.eventsBaseURL,
                             DynamicTarget.DynamicTargetStatus.getSplitChanges(since: since))
    }

    public static func getMySegments(user: String) -> Target {
        return DynamicTarget(shared.sdkBaseUrl,
                             shared.eventsBaseURL,
                             DynamicTarget.DynamicTargetStatus.getMySegments(user: user))
    }

    public static func sendImpressions(impressions: [ImpressionsTest]) -> Target {
        let target = DynamicTarget(shared.sdkBaseUrl,
                                   shared.eventsBaseURL,
                                   DynamicTarget.DynamicTargetStatus.sendImpressions)
        target.append(value: "application/json", forHttpHeader: "content-type")
        let jsonImpressions = (try? Json.encodeToJson(impressions)) ?? "[]"
        target.setBody(json: jsonImpressions)
        return target
    }

    public static func sendTrackEvents(events: [EventDTO]) -> Target {

        let target = DynamicTarget(shared.sdkBaseUrl,
                                   shared.eventsBaseURL,
                                   DynamicTarget.DynamicTargetStatus.sendTrackEvents)
        target.append(value: "application/json", forHttpHeader: "content-type")
        let jsonEvents = (try? Json.dynamicEncodeToJson(events)) ?? "[]"
        target.setBody(json: jsonEvents)

        return target
    }

    public static func sendTimeMetrics(_ times: [TimeMetric]) -> Target {
        let target = DynamicTarget(shared.sdkBaseUrl,
                                   shared.eventsBaseURL,
                                   DynamicTarget.DynamicTargetStatus.sendTimeMetrics)
        target.append(value: "application/json", forHttpHeader: "content-type")
        let jsonEvents = (try? Json.encodeToJson(times)) ?? "[]"
        target.setBody(json: jsonEvents)

        return target
    }

    public static func sendCounterMetrics(_ counters: [CounterMetric]) -> Target {
        let target = DynamicTarget(shared.sdkBaseUrl,
                                   shared.eventsBaseURL,
                                   DynamicTarget.DynamicTargetStatus.sendCounterMetrics)
        target.append(value: "application/json", forHttpHeader: "content-type")
        let jsonEvents = (try? Json.encodeToJson(counters)) ?? "[]"
        target.setBody(json: jsonEvents)

        return target
    }

    public static func sendGaugeMetrics(_ gauge: MetricGauge) -> Target {
        let target = DynamicTarget(shared.sdkBaseUrl,
                                   shared.eventsBaseURL,
                                   DynamicTarget.DynamicTargetStatus.sendGaugeMetrics)
        target.append(value: "application/json", forHttpHeader: "content-type")
        let jsonEvents = (try? Json.encodeToJson(gauge)) ?? "[]"
        target.setBody(json: jsonEvents)

        return target
    }
}
