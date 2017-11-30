//
//  ApiRequestProtocol.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

protocol RestClientRequestProtocol {
    func getResponse(errorSanitizer: @escaping (JSON, Int) -> Result<JSON>, completionHandler: @escaping (DataResponse<JSON>) -> Void) -> Self
}
