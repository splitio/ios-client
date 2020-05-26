//
// SSEClientTest.swift
// Split
//
// Created by Javier L. Avrudsky on 12/05/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SSEClientTest: XCTestCase {
    var httpClient: HttpClient?

    override func setUp() {

    }

    func test() {
        let PUSH_NOTIFICATION_CHANNELS_PARAM = "channel"
        let PUSH_NOTIFICATION_TOKEN_PARAM = "accessToken"
        let PUSH_NOTIFICATION_VERSION_PARAM = "v"
        let PUSH_NOTIFICATION_VERSION_VALUE = "1.1"
        let sseEndpoint = EndpointFactory(serviceEndpoints: <#T##ServiceEndpoints##Split.ServiceEndpoints#>.builder().build(),
                apiKey: IntegrationHelper.dummyApiKey, userKey: IntegrationHelper.dummyUserKey).streamingEndpoint

        let r = httpClient?.sendRequest(target: sseEndpoint).getResponse(errorSanitizer: <#T##@escaping (JSON, Int) -> HttpResult<JSON>##@escaping (Split.JSON, Swift.Int) -> Split.HttpResult<Split.JSON>#>, completionHandler: <#T##@escaping (HttpDataResponse<JSON>) -> Void##@escaping (Split.HttpDataResponse<Split.JSON>) -> Swift.Void#>)

        _ = httpClient.sendRequest(
                        endpoint: sseEndpoint,
                        parameters: parameters,
                        headers: nil,
                        body: body)
                .getResponse(errorSanitizer: endpoint.errorSanitizer) { response in
                    switch response.result {
                    case .success(let json):
                        if json.isNull() {
                            completion(DataResult { return nil })
                            return
                        }

                        do {
                            let parsedObject = try json.decode(T.self)
                            completion(DataResult { return parsedObject })
                        } catch {
                            completion(DataResult { throw error })
                        }
                    case .failure(let error):
                        completion(DataResult { throw error })
                    }

    }
}
