//
//  NewsApiEndpoint.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

enum StagingTarget: Target {
    
    var baseUrl: URL { return URL(string: "https://sdk-aws-staging.split.io/api")! }
    var impressionBaseURL: URL { return URL(string: "https://events-aws-staging.split.io/api/testImpressions/bulk")! }

    var apiKey: String? { return SecureDataStore.shared.getToken() } // TODO: Use the one provided on the Client
    // Insert your common headers here, for example, authorization token or accept.
    var commonHeaders: [String : String]? { return ["Authorization" : "Bearer \(SecureDataStore.shared.getToken()!)"] }
    
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
                let url = baseUrl.appendingPathComponent("splitChanges")
                let params = "?since=\(since)"
                return URL(string: params.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!, relativeTo: url)!
            case .GetMySegments(let user):
                return baseUrl.appendingPathComponent("mySegments").appendingPathComponent(user)
            
        case .GetImpressions():
            return impressionBaseURL
        }
    }
    
    var errorSanitizer: (JSON, Int) -> Result<JSON> {
        return { json, statusCode in
            guard statusCode >= 200 && statusCode <= 203 else {
                let error = NSError(domain: InfoUtils.bundleNameKey(), code: ErrorCode.Undefined, userInfo: nil)
                return .failure(error)
            }
            return .success(json)
        }
    }
}
