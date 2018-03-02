//
//  EnvironmentTargetManager.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/2/18.
//

import Foundation

class EnvironmentTargetManager {
    
    var sdkBaseUrl: URL
    var eventsBaseURL: URL
    
    static let shared: EnvironmentTargetManager = {
        let instance = EnvironmentTargetManager()
        return instance
    }()
    
    //Guarantee singleton instance
    private init(){}
    
    public static func GetSplitChanges(since: Int64) -> Target {
        return DynamicTarget("","",DynamicTarget.DynamicTargetStatus.GetSplitChanges(since: since)())
    }
    
    public static func GetMySegments(user: String) -> Target {
        return DynamicTarget("","",DynamicTarget.DynamicTargetStatus.GetMySegments(user: user))
    }
    
    public static func GetImpressions() -> Target {
        return DynamicTarget("","",DynamicTarget.DynamicTargetStatus.GetImpressions())
    }
    
}
