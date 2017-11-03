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
    var apiKey: String? { return "k6ogh4k721d4p671h6spc04n0pg1a6h1cmpq" } // TODO: Use the one provided on the Client
    // Insert your common headers here, for example, authorization token or accept.
    var commonHeaders: [String : String]? { return ["Authorization" : "Bearer \(apiKey!)"] }
    
    case GetSplitChanges(since: Int64)
    case GetMySegments(user: String)
    
    // MARK: - Public Properties
    var method: HTTPMethod {
        switch self {
            case .GetSplitChanges:
                return .get
            case .GetMySegments:
                return .get
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
