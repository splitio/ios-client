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
    var kSinceParameter: String { "since" }
    func getSplitChanges(since: Int64, completion: @escaping (DataResult<SplitChange>) -> Void) {
        self.execute(
                endpoint: endpointFactory.splitChangesEndpoint,
                parameters: [kSinceParameter: since],
                completion: completion)
    }
}
