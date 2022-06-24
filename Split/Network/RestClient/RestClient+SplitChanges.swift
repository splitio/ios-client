//
//  RestClient+SplitChanges.swift
//  Split
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation

protocol RestClientSplitChanges: RestClient {
    func getSplitChanges(since: Int64,
                         till: Int64?,
                         headers: HttpHeaders?,
                         completion: @escaping (DataResult<SplitChange>) -> Void)
}

extension DefaultRestClient: RestClientSplitChanges {
    func getSplitChanges(since: Int64,
                         till: Int64?,
                         headers: HttpHeaders?,
                         completion: @escaping (DataResult<SplitChange>) -> Void) {
        var parameters = ["since": since]
        if let till = till {
            parameters["till"] = till
        }
        self.execute(
            endpoint: endpointFactory.splitChangesEndpoint,
            parameters: parameters,
            headers: headers,
            completion: completion)
    }
}
