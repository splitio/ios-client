//
//  RestClient+Source.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation
import SwiftyJSON

extension RestClient {
    
    func getTreatments(keys: [Key], attributes: [String : Any]? = nil, completion: @escaping (DataResult<[Treatment]>) -> Void) {
        self.execute(target: CallhomeTarget.GetTreatments(keys: keys, attributes: attributes), completion: completion) { json in
            let treatments = json.arrayValue.map { (json: JSON) -> Treatment in
                let treatment = Treatment(json)
                return treatment
            }
            return treatments
        }
    }
}
