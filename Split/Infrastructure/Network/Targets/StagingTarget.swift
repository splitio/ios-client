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
    var apiKey: String? { return "89d5uvpc1ktg9gdj1nrhk0coh6k5vsqj1uu4" } // TODO: Use the one provided on the Client
    // Insert your common headers here, for example, authorization token or accept.
    var commonHeaders: [String : String]? { return ["Authorization" : "Bearer \(apiKey!)"] }
    
    case GetSplitChanges(since: Int64)
    
    // MARK: - Public Properties
    var method: HTTPMethod {
        switch self {
            case .GetSplitChanges:
                return .get
        }
    }
    
    var url: URL {
        switch self {
            case .GetSplitChanges(let since):
                let url = baseUrl.appendingPathComponent("splitChanges")
                let params = "?since=\(since)"
                return URL(string: params.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!, relativeTo: url)!
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
