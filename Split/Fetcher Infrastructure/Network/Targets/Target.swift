//
//  Endpoint.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

protocol Target {
    var apiKey: String? { get }
    var commonHeaders: [String : String]? { get }
    var method: HTTPMethod { get }
    var url: URL { get }
    var errorSanitizer: (JSON, Int) -> Result<JSON> { get }
}
