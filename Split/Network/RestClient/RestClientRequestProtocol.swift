//
//  ApiRequestProtocol.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation

protocol RestClientRequestProtocol {
    func getResponse(errorSanitizer: @escaping (JSON, Int) -> HttpResult<JSON>,
                     completionHandler: @escaping (HttpDataResponse<JSON>) -> Void) -> Self
}
