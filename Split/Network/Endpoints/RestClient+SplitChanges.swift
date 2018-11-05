//
//  RestClient+Source.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation

extension RestClient {
    
    func getSplitChanges(since: Int64, completion: @escaping (DataResult<SplitChange>) -> Void) {
        self.execute(target: EnvironmentTargetManager.getSplitChanges(since: since), completion: completion)
    }
    
}
