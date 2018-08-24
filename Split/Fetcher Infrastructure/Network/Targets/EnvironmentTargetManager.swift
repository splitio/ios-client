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
            self.eventsBaseURL = URL(string:newValue) ?? URL(string:kDefaultEventsBaseUrl)!
        }
    }
    
    var sdkEndpoint: String {
        get {
            return sdkBaseUrl.absoluteString
        }
        set {
            self.sdkBaseUrl = URL(string:newValue) ?? URL(string:kDefaultSdkBaseUrl)!
        }
    }
    
    static let shared: EnvironmentTargetManager = {
        let instance = EnvironmentTargetManager()
        return instance
    }()
    
    //Guarantee singleton instance
    private init(){
        sdkBaseUrl = URL(string:kDefaultSdkBaseUrl)!
        eventsBaseURL = URL(string:kDefaultEventsBaseUrl)!
    }
    
    public static func GetSplitChanges(since: Int64) -> Target {
        return DynamicTarget(shared.sdkBaseUrl,
                             shared.eventsBaseURL,
                             DynamicTarget.DynamicTargetStatus.GetSplitChanges(since: since))
    }
    
    public static func GetMySegments(user: String) -> Target {
        return DynamicTarget(shared.sdkBaseUrl,
                             shared.eventsBaseURL,
                             DynamicTarget.DynamicTargetStatus.GetMySegments(user: user))
    }
    
    public static func GetImpressions(impressions: String) -> Target {
        
        
        let target = DynamicTarget(shared.sdkBaseUrl,
                             shared.eventsBaseURL,
                             DynamicTarget.DynamicTargetStatus.GetImpressions())
        target.append(value: "application/json", forHttpHeader: "content-type")
        target.setBody(json: impressions)
        return target
    }
    
    public static func SendTrackEvents(events: [EventDTO]) -> Target {
        let target = DynamicTarget(shared.sdkBaseUrl,
                                   shared.eventsBaseURL,
                                   DynamicTarget.DynamicTargetStatus.SendTrackEvents())
        target.append(value: "application/json", forHttpHeader: "content-type")
        let jsonEvents = (try? Json.encodeToJson(events)) ?? "[]"
        target.setBody(json: jsonEvents)
        
        return target
    }
}
