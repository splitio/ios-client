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
        self.execute(
            endpoint: endpointFactory.splitChangesEndpoint,
            parameters: buildParameters(since: since, till: till),
            headers: headers,
            completion: completion)
    }

    private func buildParameters(since: Int64,
                                 till: Int64?) -> HttpParameters {
        var parameters: [HttpParameter] = []
        if !Spec.flagsSpec.isEmpty() {
            parameters.append(HttpParameter(key: "s", value: Spec.flagsSpec))
        }

        parameters.append(HttpParameter(key: "since", value: since))
        parameters.append(HttpParameter(key: "sets"))
        parameters.append(HttpParameter(key: "names"))
        parameters.append(HttpParameter(key: "prefixes"))

        if let till = till {
            parameters.append(HttpParameter(key: "till", value: till))
        }

        return HttpParameters(parameters)
    }
}
