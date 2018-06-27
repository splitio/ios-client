//
//  DynamicTarget.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/2/18.
//

import Foundation

class DynamicTarget: Target {
  
    public enum DynamicTargetStatus {
        case GetSplitChanges(since: Int64)
        case GetMySegments(user: String)
        case GetImpressions()
    }
    
    var internalStatus:DynamicTargetStatus
    
    var sdkBaseUrl: URL
    
    var eventsBaseURL: URL
    
    var apiKey: String? { return SecureDataStore.shared.getToken() }
    
    var commonHeaders: [String : String]?
    
    var parameters: [String:Any]? = nil
    
    var body: Data? {
        return bodyContent
    }
    
    private var bodyContent: Data? = nil
    
    public init(_ sdkBaseUrl:URL, _ eventsBaseURL:URL, _ status: DynamicTargetStatus ){
        self.sdkBaseUrl = sdkBaseUrl
        self.eventsBaseURL = eventsBaseURL
        
        self.commonHeaders = [
            "authorization" : "Bearer " + SecureDataStore.shared.getToken()!,
            "splitsdkversion" : Version.toString()
        ]
        
        self.internalStatus = status
        
    }
    
    
    //public var method: HTTPMethod
    public var method: HttpMethod {
        switch self.internalStatus {
        case .GetSplitChanges:
            return .get
        case .GetMySegments:
            return .get
        case .GetImpressions:
            return .post
        }
    }
    
    public var url: URL {
        switch self.internalStatus {
        case .GetSplitChanges(let since):
            let url = sdkBaseUrl.appendingPathComponent("splitChanges")
            let params = "?since=\(since)"
            return URL(string: params.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!, relativeTo: url)!
        case .GetMySegments(let user):
            return sdkBaseUrl.appendingPathComponent("mySegments").appendingPathComponent(user)
            
        case .GetImpressions():
            return eventsBaseURL.appendingPathComponent("testImpressions").appendingPathComponent("bulk")
          
        }
    }
    
    func append(value: String, forHttpHeader headerKey: String) {
        if commonHeaders == nil {
            commonHeaders = [String:String]()
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
