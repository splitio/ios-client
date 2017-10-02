//
//  RestClient+MySegments.swift
//  Pods
//
//  Created by Brian Sztamfater on 29/9/17.
//
//

import Foundation
import SwiftyJSON

extension RestClient {
    
    func getMySegments(user: String, completion: @escaping (DataResult<[String]>) -> Void) {
        self.execute(target: StagingTarget.GetMySegments(user: user), completion: completion) { json in
            return json["mySegments"].arrayValue.map { (json: JSON) -> String in
                return json["name"].stringValue
            }
        }
    }
    
}
