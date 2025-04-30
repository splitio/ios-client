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
                         rbSince: Int64?,
                         till: Int64?,
                         headers: HttpHeaders?,
                         completion: @escaping (DataResult<TargetingRulesChange>) -> Void)
}

extension DefaultRestClient: RestClientSplitChanges {
    func getSplitChanges(since: Int64,
                         rbSince: Int64?,
                         till: Int64?,
                         headers: HttpHeaders?,
                         completion: @escaping (DataResult<TargetingRulesChange>) -> Void) {
        self.execute(
            endpoint: endpointFactory.splitChangesEndpoint,
            parameters: buildParameters(since: since, rbSince: rbSince, till: till),
            headers: headers,
            completion: completion)
    }

    private func buildParameters(since: Int64, rbSince: Int64?, till: Int64?) -> HttpParameters {
        
        var parameters: [HttpParameter] = []
        if !Spec.flagsSpec.isEmpty() {
            parameters.append(HttpParameter(key: "s", value: Spec.flagsSpec))
        }

        // Parameters order is IMPORTANT (if the order is wrong, the CDN cache won't properly work)
        parameters.append(HttpParameter(key: "since", value: since))
        if rbSince != nil { parameters.append(HttpParameter(key: "rbSince", value: rbSince)) }
        parameters.append(HttpParameter(key: "sets"))
        parameters.append(HttpParameter(key: "names"))
        parameters.append(HttpParameter(key: "prefixes"))
        if till != nil { parameters.append(HttpParameter(key: "till", value: till)) }
             
        return HttpParameters(parameters)
    }
}
