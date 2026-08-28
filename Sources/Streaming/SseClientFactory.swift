//
//  SseClientFactory.swift
//  Split
//
//  Created by Javier Avrudsky on 02-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
#if SWIFT_PACKAGE
import Http
#endif

public protocol SseClientFactory {
    func create() -> SseClient
}

public class DefaultSseClientFactory: SseClientFactory {
    private let endpoint: Endpoint
    private let httpClient: HttpClient
    private let sseHandler: SseHandler

    public init(endpoint: Endpoint,
         httpClient: HttpClient,
         sseHandler: SseHandler) {
        self.endpoint = endpoint
        self.httpClient = httpClient
        self.sseHandler = sseHandler
    }

    public func create() -> SseClient {
        DefaultSseClient(endpoint: endpoint,
                                httpClient: httpClient,
                                sseHandler: sseHandler)
    }
}
