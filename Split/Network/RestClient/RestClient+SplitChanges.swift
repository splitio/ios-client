//
//  RestClient+SplitChanges.swift
//  Split
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation

protocol RestClientSplitChanges: RestClient {
    func getSplitChanges(since: Int64, completion: @escaping (DataResult<SplitChange>) -> Void)
}

extension DefaultRestClient: RestClientSplitChanges {
    func getSplitChanges(since: Int64, completion: @escaping (DataResult<SplitChange>) -> Void) {
        var kSinceParameter: String { "since" }
        self.execute(
            endpoint: endpointFactory.splitChangesEndpoint,
            parameters: [kSinceParameter: since],
            completion: completion)
    }
}
