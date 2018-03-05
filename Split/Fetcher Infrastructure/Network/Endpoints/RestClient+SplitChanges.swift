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
    
    func getSplitChanges(since: Int64, completion: @escaping (DataResult<SplitChange>) -> Void) {
        self.execute(target: EnvironmentTargetManager.GetSplitChanges(since: since), completion: completion) { json in
            return SplitChange(json)
        }
    }
}
