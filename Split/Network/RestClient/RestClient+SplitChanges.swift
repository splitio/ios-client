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
            parameters.append(HttpParameter("s", Spec.flagsSpec))
        }

        parameters.append(HttpParameter("since", since))
        parameters.append(HttpParameter("sets"))
        parameters.append(HttpParameter("names"))
        parameters.append(HttpParameter("prefixes"))

        if let till = till {
            parameters.append(HttpParameter("till", till))
        }

        return HttpParameters(parameters)
    }
}
