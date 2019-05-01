//
//  RestClient+SplitChanges.swift
//  Split
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation

protocol RestClientSplitChanges: RestClientProtocol {
    func getSplitChanges(since: Int64, completion: @escaping (DataResult<SplitChange>) -> Void)
}

extension RestClient: RestClientSplitChanges {
    func getSplitChanges(since: Int64, completion: @escaping (DataResult<SplitChange>) -> Void) {
        self.execute(target: EnvironmentTargetManager.getSplitChanges(since: since), completion: completion)
    }
}
