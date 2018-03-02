//
//  ConfigurableTarget.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/2/18.
//

import Foundation
import Alamofire
import SwiftyJSON

enum ConfigurableTarget: Target {
    var sdkBaseUrl: URL { return TargetConfiguration.shared.getSdkEndpoint() }
    var eventsBaseURL: URL { return TargetConfiguration.shared.getEventsEndpoint() }
    
    var apiKey: String? { return SecureDataStore.shared.getToken() }
    
    var commonHeaders: [String : String]? {return TargetConfiguration.shared.getCommonHeaders()}
    
    
    case GetSplitChanges(since: Int64)
    case GetMySegments(user: String)
    case GetImpressions()
    
    
    // MARK: - Public Properties
    var method: HTTPMethod {
        switch self {
        case .GetSplitChanges:
            return .get
        case .GetMySegments:
            return .get
        case .GetImpressions:
            return .post
        }
    }
    
    var url: URL {
        switch self {
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
    
    var errorSanitizer: (JSON, Int) -> Result<JSON> {
        return { json, statusCode in
            guard statusCode >= 200 && statusCode <= 203  else {
                let error = NSError(domain: InfoUtils.bundleNameKey(), code: ErrorCode.Undefined, userInfo: nil)
                return .failure(error)
            }
            return .success(json)
        }
    }
}
