//
//  ApiProtocol.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension DataRequest: RestClientRequestProtocol {
    
    static func responseSerializer(errorSanitizer: @escaping (JSON, Int) -> Result<JSON>) -> DataResponseSerializer<JSON> {
        return DataResponseSerializer<JSON> { request, response, data, error in
            if let error = error {
                return .failure(error)
            }
            
            guard let validData = data else {
                let reason = "Data could not be serialized. Input data was nil."
                return .failure(NSError(domain: InfoUtils.bundleNameKey(), code: ErrorCode.SerializationFailed, userInfo: [NSLocalizedDescriptionKey : reason]))
            }
            
            let json = JSON(data: validData)

            return errorSanitizer(json, response!.statusCode)
        }
    }
    
    func getResponse(errorSanitizer: @escaping (JSON, Int) -> Result<JSON>, completionHandler: @escaping (DataResponse<JSON>) -> Void) -> Self {
        self.validate { request, response, data in
            return .success
        }
        .response(responseSerializer: DataRequest.responseSerializer(errorSanitizer: errorSanitizer)) { response in
            completionHandler(response)
        }
        return self;
    }
    
}
