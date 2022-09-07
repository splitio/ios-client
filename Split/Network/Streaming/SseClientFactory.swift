//
//  SseClientFactory.swift
//  Split
//
//  Created by Javier Avrudsky on 02-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol SseClientFactory {
    func create() -> SseClient
}

class DefaultSseClientFactory: SseClientFactory {
    private let endpoint: Endpoint
    private let httpClient: HttpClient
    private let sseHandler: SseHandler

    init(endpoint: Endpoint,
         httpClient: HttpClient,
         sseHandler: SseHandler) {
        self.endpoint = endpoint
        self.httpClient = httpClient
        self.sseHandler = sseHandler
    }

    func create() -> SseClient {
        return DefaultSseClient(endpoint: endpoint,
                                httpClient: httpClient,
                                sseHandler: sseHandler)
    }
}
