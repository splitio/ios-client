//
//  EnvironmentTargetManager.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/2/18.
//

import Foundation

class EnvironmentTargetManager {
    
    var sdkBaseUrl: URL = URL(string:"https://sdk.split.io/api")!
    var eventsBaseURL: URL = URL(string:"https://events.split.io/api")!
    
    static let shared: EnvironmentTargetManager = {
        let instance = EnvironmentTargetManager()
        return instance
    }()
    
    //Guarantee singleton instance
    private init(){}
    
    public func sdkEndpoint(_ url: String) {
        self.sdkBaseUrl = URL(string:url)!
    }
    
    public func eventsEndpoint(_ url: String) {
        self.eventsBaseURL = URL(string:url)!
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
    
    public static func GetImpressions() -> Target {
        return DynamicTarget(shared.sdkBaseUrl,
                             shared.eventsBaseURL,
                             DynamicTarget.DynamicTargetStatus.GetImpressions())
    }
    
}
