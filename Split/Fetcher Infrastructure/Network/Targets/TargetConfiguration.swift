//
//  TargetConfiguration.swift
//  Split
//
//  Created by Sebastian Arrubia on 2/26/18.
//

import Foundation

class TargetConfiguration {
    
    private var sdkURL: URL = URL(string:"https://sdk.split.io/api")!
    private var eventsURL: URL = URL(string:"https://events.split.io/api")!
    private var commonHeaders: [String : String] = [
        "authorization" : "Bearer " + SecureDataStore.shared.getToken()!,
        "splitsdkversion" : Version.toString()
    ]
    
    
    static let shared: TargetConfiguration = {
        let instance = TargetConfiguration()
        return instance
    }()
    
    //Guarantee singleton instance
    private init(){}
    
    public static func sdkEndpoint(url: String){
        shared.sdkURL = URL(string:url)!
    }
    
    public static func getSdkEndpoint() -> URL {
        return shared.sdkURL
    }
    
    public static func eventsEndpoint(url: String){
        shared.eventsURL = URL(string: url)!
    }
    
    public static func getEventsEndpoint() -> URL {
        return shared.eventsURL
    }
    
    public static func getCommonHeaders() -> [String:String] {
        return shared.commonHeaders
    }

}
