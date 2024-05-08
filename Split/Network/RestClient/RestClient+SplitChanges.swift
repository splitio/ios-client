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
        var parameters: [String: Any] = ["since": since]
        if let till = till {
            parameters["till"] = till
        }
        if !Spec.flagsSpec.isEmpty() {
            parameters["s"] = Spec.flagsSpec
        }
        self.execute(
            endpoint: endpointFactory.splitChangesEndpoint,
            parameters: HttpParameters(values: parameters, order: ["s", "since", "sets", "names", "prefixes", "till"]),
            headers: headers,
            completion: completion)
    }
}
