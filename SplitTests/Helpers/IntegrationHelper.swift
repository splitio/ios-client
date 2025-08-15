//
//  IntegrationHelper.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 01/10/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

class IntegrationHelper {

    static var mockServiceEndpoint: ServiceEndpoints {
        return ServiceEndpoints.builder().set(sdkEndpoint: mockEndPoint).set(eventsEndpoint: mockEndPoint).build()
    }

    static var dummyApiKey: String {
        return "99049fd8653247c5ea42bc3c1ae2c6a42bc3"
    }

    static var dummyFolderName: String {
        return "2a1099049fd8653247c5ea42bOIajMRhH0R0FcBwJZM4ca7zj6HAq1ZDS"
    }

    static var dummyUserKey: String {
        return "CUSTOMER_ID"
    }

    static var mockEndPoint: String {
        return "http://localhost:8080"
    }

    static var emptyMySegments: String {
        return """
          {
          \"ms\": {
                      \"k\": []
          },
                    \"ls\": {
                      \"k\": []
          },
          }
          """
    }

    static var emptySplitChanges: String {
        return "{\"ff\": {\"d\":[], \"s\": 9567456937865, \"t\": 9567456937869 }, \"rbs\": {\"d\":[], \"s\": -1, \"t\": -1 }}"
    }

    static func emptySplitChanges(since: Int, till: Int) -> String {
        return "{\"ff\": {\"d\":[], \"s\": \(since), \"t\": \(till) }, \"rbs\": {\"d\":[], \"s\": \(since), \"t\": \(till) }}"
    }


    static func buildSegments(regular: [String] = [], large: [String] = [], cn: Int64 = -1) -> String {
        let reg = toSegments(regular)
        let lar = toSegments(large)
        let res =  """
          {
          \"ms\": {
                      \"k\": [\(reg)]
          },
                    \"ls\": {
                      \"k\": [\(lar)]
          }
          }
          """
        print(res)
        return res
    }

    static func toSegments(_ segments: [String]) -> String {
        var res = [String]()
        for seg in segments {
            res.append("{\"n\": \"\(seg)\"}")
        }
        return res.joined(separator: ",")
    }

    static func dummyImpressions() -> String {
        return """
        [{\"testName\": \"test1\", \"keyImpressions\":[
        {
        \"feature\": \"test1\",
        \"keyName\": \"thekey\",
        \"treatment\": \"on\",
        \"timestamp\": 111,
        \"changeNumber\": 999,
        \"label\": \"default rule\"
        }
        ]}]
        """
    }

    static func dummyReducedImpressions() -> String {
        return """
        [{\"f\": \"test1\", \"i\":[
        {
        \"b\": \"bkey\",
        \"k\": \"thekey\",
        \"t\": \"on\",
        \"m\": 111,
        \"c\": 999,
        \"r\": \"default rule\"
        }
        ]}]
        """
    }

    static func buildImpressionKey(impression: Impression) -> String {
        return buildImpressionKey(key: impression.keyName!, splitName: impression.feature!, treatment: impression.treatment!)
    }

    static func buildImpressionKey(impression: KeyImpression) -> String {
        return buildImpressionKey(key: impression.keyName, splitName: impression.featureName!, treatment: impression.treatment)
    }

    static func buildImpressionKey(key: String, splitName: String, treatment: String) -> String {
        return "(\(key)_\(splitName)_\(treatment)"
    }

    static func buildImpressionsFromJson(content: String) throws -> [ImpressionsTest] {
        return try Json.decodeFrom(json: content, to: [ImpressionsTest].self)
    }

    static func buildEventsFromJson(content: String) throws -> [EventDTO] {
        return try Json.dynamicDecodeFrom(json: content, to: [EventDTO].self)
    }

    static func getTrackEventBy(value: Double, trackHits: [String]) -> EventDTO? {
        let hits = trackHits
        for req in hits {
            var lastEventHitEvents: [EventDTO] = []
            do {
                lastEventHitEvents = try buildEventsFromJson(content: req)
            } catch {
                print("error: \(error)")
            }
            let events = lastEventHitEvents.filter { $0.value == value }
            if events.count > 0 {
                return events[0]
            }
        }
        return nil
    }


    static func dummySseResponse(delay: Int = 0) -> String {
        return """
        {
        \"pushEnabled\": true,
        \"connDelay\": \(delay),
        \"token\": \"eyJhbGciOiJIUzI1NiIsImtpZCI6IjVZOU05US45QnJtR0EiLCJ0eXAiOiJKV1QifQ.eyJ4LWFibHktY2FwYWJpbGl0eSI6IntcIk16TTVOamMwT0RjeU5nPT1fTVRFeE16Z3dOamd4X01UY3dOVEkyTVRNME1nPT1fbXlTZWdtZW50c1wiOltcInN1YnNjcmliZVwiXSxcIk16TTVOamMwT0RjeU5nPT1fTVRFeE16Z3dOamd4X3NwbGl0c1wiOltcInN1YnNjcmliZVwiXSxcImNvbnRyb2xfcHJpXCI6W1wic3Vic2NyaWJlXCIsXCJjaGFubmVsLW1ldGFkYXRhOnB1Ymxpc2hlcnNcIl0sXCJjb250cm9sX3NlY1wiOltcInN1YnNjcmliZVwiLFwiY2hhbm5lbC1tZXRhZGF0YTpwdWJsaXNoZXJzXCJdfSIsIngtYWJseS1jbGllbnRJZCI6ImNsaWVudElkIiwiZXhwIjoxNjAyMjY5NjU1LCJpYXQiOjE2MDIyNjYwNTV9.nRtxU6WPt4sdgxcV3TD21pYwymbKI1nSamTI72GDZFw"
        }
        """
    }

    static func sseDisabledResponse() -> String {
        return """
        {
        \"pushEnabled\": false
        }
        """
    }

    static func getChanges(fileName: String) -> SplitChange? {
        var change: SplitChange?
        if let content = FileHelper.readDataFromFile(sourceClass: IntegrationHelper(), name: fileName, type: "json") {
            change = try? Json.decodeFrom(json: content, to: TargetingRulesChange.self).featureFlags
        }
        return change
    }

    static func mySegments(names: [String]) -> String {
        return TestingHelper.newAllSegmentsChangeJson(ms: names)
    }

    static func tlog(_ message: String) {
        print("TRVLOG -> \(message)")
    }

    static func enabledTelemetry() -> TelemetryConfigHelper {
        return TelemetryConfigHelperStub(enabled: true)
    }

    static func loadSplitChangeFile(name fileName: String) -> SplitChange? {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json"),
            let change = try? Json.decodeFrom(json: file, to: TargetingRulesChange.self) {
            return change.featureFlags
        }
        return nil
    }

    static func loadSplitChangeFileJson(name fileName: String, sourceClass: Any) -> String? {
        if let jsonContent = FileHelper.readDataFromFile(sourceClass: sourceClass, name: fileName, type: "json") {
            return jsonContent
        }
        return nil
    }

    static func ably40012Error() -> String {
        return """
            id:cf74eb42-f687-48e4-ad18-af2125110aac
            event:error
            data:{ "code": 40012,  "statusCode":400,  "message": "Invalid client id"}
            """
    }

    static func describeEvent(_ event: SplitInternalEvent) -> String {
        switch event {
            case .mySegmentsUpdated:
                return "mySegmentsUpdated"
            case .splitsUpdated:
                return "splitsUpdated"
            case .mySegmentsLoadedFromCache:
                return "mySegmentsLoadedFromCache"
            case .splitsLoadedFromCache:
                return "splitsLoadedFromCache"
            case .attributesLoadedFromCache:
                return "attributesLoadedFromCache"
            case .sdkReadyTimeoutReached:
                return "sdkReadyTimeoutReached"
            case .splitKilledNotification:
                return "splitKilledNotification"
            case .myLargeSegmentsUpdated:
                return "myLargeSegmentsUpdated"
            case .myLargeSegmentsLoadedFromCache:
                return "myLargeSegmentsLoadedFromCache"
            case .sdkError:
                return "sdkError"
        }
    }

    static var dummyCipherKey: Data {
        return String("11F17550-01EA-45").dataBytes!
    }
}
