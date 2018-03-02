//
//  TargetConfiguration.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/2/18.
//

import Foundation

class TargetConfiguration {

    //private var sdkURL: URL = URL(string:"https://sdk.split.io/api")!
    //private var eventsURL: URL = URL(string:"https://events.split.io/api")!

    private var sdkURL: URL = URL(string:"https://sdk-aws-staging.split.io/api")!
    private var eventsURL: URL = URL(string:"https://events-aws-staging.split.io/api")!
    
    private var commonHeaders: [String : String] = [
        "authorization" : "Bearer " + SecureDataStore.shared.getToken()!,
        "splitsdkversion" : Version.toString()
    ]
    
    private let endpointsLock = NSLock()
    
    static let shared: TargetConfiguration = {
        let instance = TargetConfiguration()
        return instance
    }()
    
    //Guarantee singleton instance
    private init(){}
    
    public func sdkEndpoint(url: String){
        endpointsLock.lock()
        self.sdkURL = URL(string:url)!
        endpointsLock.unlock()
    }
    
    public func getSdkEndpoint() -> URL {
        return self.sdkURL
    }
    
    public func eventsEndpoint(url: String){
        endpointsLock.lock()
        self.eventsURL = URL(string: url)!
        endpointsLock.unlock()
    }
    
    public func getEventsEndpoint() -> URL {
        return self.eventsURL
    }
    
    public func getCommonHeaders() -> [String:String] {
        return self.commonHeaders
    }
    
}
