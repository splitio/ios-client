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

enum CallhomeTarget: Target {
    
    var baseUrl: URL { return URL(string: InfoUtils.valueForKey(key: "CALLHOME_URL"))! }
    var apiKey: String? { return InfoUtils.valueForKey(key: "CALLHOME_API_KEY") }
    // Insert your common headers here, for example, authorization token or accept.
    var commonHeaders: [String : String]? { return ["Authorization" : "Bearer \(apiKey!)"] }
    
    case GetTreatments(keys: [Key], attributes: [String : Any]?)
    
    // MARK: - Public Properties
    var method: HTTPMethod {
        switch self {
            case .GetTreatments:
                return .get
        }
    }
    
    var url: URL {
        switch self {
            case .GetTreatments(let keys, let attributes):
                let url = baseUrl.appendingPathComponent("get-treatments")
                let keysJSON = keys.map { $0.toJSON() }
                let params = "?keys=\(JSON(keysJSON).rawString(options:JSONSerialization.WritingOptions(rawValue: 0))!)&attributes=\(attributes != nil ? attributes!.toJSONString()! : "")"
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
