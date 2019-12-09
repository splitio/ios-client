//
//  DynamicTarget.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/2/18.
//

import Foundation

class DynamicTarget: Target {
    enum DynamicTargetStatus {
        case getSplitChanges(since: Int64)
        case getMySegments(user: String)
        case sendImpressions
        case sendTrackEvents
        case sendTimeMetrics
        case sendCounterMetrics
        case sendGaugeMetrics
    }

    var internalStatus: DynamicTargetStatus
    var sdkBaseUrl: URL
    var eventsBaseURL: URL
    var apiKey: String? { return SecureDataStore.shared.getToken() }
    var commonHeaders: [String: String]?
    var parameters: [String: Any]?
    var body: Data? {
        return bodyContent
    }
    private var bodyContent: Data?

    init(_ sdkBaseUrl: URL, _ eventsBaseURL: URL, _ status: DynamicTargetStatus) {
        self.sdkBaseUrl = sdkBaseUrl
        self.eventsBaseURL = eventsBaseURL

        if let token = SecureDataStore.shared.getToken() {
            self.commonHeaders = [
                "authorization": "Bearer " + token,
                "splitsdkversion": Version.sdk
            ]
        } else {
            Logger.e("API key is null")
        }

        self.internalStatus = status

    }

    //public var method: HTTPMethod
    public var method: HttpMethod {
        switch self.internalStatus {
        case .getSplitChanges:
            return .get
        case .getMySegments:
            return .get
        case .sendImpressions:
            return .post
        case .sendTrackEvents:
            return .post
        case .sendTimeMetrics:
            return .post
        case .sendCounterMetrics:
            return .post
        case .sendGaugeMetrics:
            return .post
        }
    }

    public var url: URL {
        switch self.internalStatus {
        case .getSplitChanges(let since):
            let url = sdkBaseUrl.appendingPathComponent("splitChanges")
            let params = "?since=\(since)"
            return URL(string: params.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!, relativeTo: url)!

        case .getMySegments(let user):
            return sdkBaseUrl.appendingPathComponent("mySegments").appendingPathComponent(user)

        case .sendImpressions:
            return eventsBaseURL.appendingPathComponent("testImpressions").appendingPathComponent("bulk")

        case .sendTrackEvents:
            return eventsBaseURL.appendingPathComponent("events").appendingPathComponent("bulk")

        case .sendTimeMetrics:
            return eventsBaseURL.appendingPathComponent("metrics").appendingPathComponent("times")

        case .sendCounterMetrics:
            return eventsBaseURL.appendingPathComponent("metrics").appendingPathComponent("counters")

        case .sendGaugeMetrics:
            return eventsBaseURL.appendingPathComponent("metrics").appendingPathComponent("gauge")
        }
    }

    func append(value: String, forHttpHeader headerKey: String) {
        if commonHeaders == nil {
            commonHeaders = [String: String]()
        }
        commonHeaders![headerKey] = value
    }

    func setBody(data: Data) {
        bodyContent = data
    }

    func setBody(json: String) {
        bodyContent = json.data(using: .utf8)
    }

    public var errorSanitizer: (JSON, Int) -> HttpResult<JSON> {
        return { json, statusCode in
            guard statusCode >= 200 && statusCode <= 203  else {
                let error = NSError(domain: InfoUtils.bundleNameKey(), code: ErrorCode.Undefined, userInfo: nil)
                return .failure(error)
            }
            return .success(json)
        }
    }
}
