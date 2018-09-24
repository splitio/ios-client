//
//  RestClient+Impressions.swift
//  SwiftSeedProject
//
//  Created by Javier Avrudsky on 6/4/18.
//  Copyright © 2018 Split Software. All rights reserved.
//

import Foundation

extension RestClient {
    
  func sendImpressions(impressions: [ImpressionsTest], completion: @escaping (DataResult<EmptyValue>) -> Void) {
      
    self.execute(target: EnvironmentTargetManager.sendImpressions(impressions: impressions), completion: completion)
    }
}
