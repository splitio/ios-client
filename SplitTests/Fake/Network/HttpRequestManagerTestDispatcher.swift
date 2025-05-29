//
//  HttpRequestManagerFake.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 14/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//
@testable import Split

import Foundation

struct TestDispatcherResponse {
    let code: Int
    let data: Data?
    let error: HttpError?
    init(code: Int, data: Data? = nil, error: HttpError? = nil) {
        self.code = code
        self.data = data
        self.error = error
    }
}

typealias HttpClientTestDispatcher = (HttpDataRequest) -> TestDispatcherResponse

class TestStreamResponseBinding {
    let code: Int
    let request: HttpStreamRequest

    static func createFor(request: HttpStreamRequest, code: Int) -> TestStreamResponseBinding {
        return TestStreamResponseBinding(code: code, request: request)
    }

    private init(code: Int, request: HttpStreamRequest) {
        self.code = code
        self.request = request
    }

    func push(message: String) {
        request.notifyIncomingData(Data(message.utf8))
    }

    func complete(error: HttpError?) {
        request.complete(error: error)
    }

    func close() {
        request.close()
    }
}

typealias TestStreamResponseBindingHandler = (HttpStreamRequest) -> TestStreamResponseBinding

class HttpRequestManagerTestDispatcher: HttpRequestManager {
    private var streamingBinding = [TestStreamResponseBinding]()
    private var dispatcher: HttpClientTestDispatcher
    private var streamingHandler: TestStreamResponseBindingHandler
    private var queue = DispatchQueue.reqManager

    init(
        dispatcher: @escaping HttpClientTestDispatcher,
        streamingHandler: @escaping TestStreamResponseBindingHandler) {
        self.dispatcher = dispatcher
        self.streamingHandler = streamingHandler
    }

    func addRequest(_ request: HttpRequest) {
        if let dataRequest = request as? HttpDataRequest {
            let response = dispatcher(dataRequest)
            queue.asyncAfter(deadline: DispatchTime.now() + 0.1) { [weak self] in
                guard let self = self else { return }
                dataRequest.setResponse(code: response.code)
                self.queue.asyncAfter(deadline: DispatchTime.now() + 0.1) { [weak self] in
                    guard let self = self else { return }
                    if let data = response.data {
                        dataRequest.notifyIncomingData(data)
                    }
                    self.queue.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                        dataRequest.complete(error: response.error)
                    }
                }
            }

        } else if let streamRequest = request as? HttpStreamRequest {
            queue.asyncAfter(deadline: DispatchTime.now() + 0.2) { [weak self] in
                guard let self = self else { return }
                self.queue.async(flags: .barrier) { [weak self] in
                    guard let self = self else { return }
                    let binding = self.streamingHandler(streamRequest)
                    request.setResponse(code: binding.code)
                    self.streamingBinding.append(binding)
                }
            }
        }
    }

    func append(data: Data, to taskIdentifier: Int) {}

    func complete(taskIdentifier: Int, error: HttpError?) {}

    func set(responseCode: Int, to taskIdentifier: Int) -> Bool {
        return true
    }

    func destroy() {}
}

extension HttpDataRequest {
    func isSplitEndpoint() -> Bool {
        return url.absoluteString.contains("splitChanges")
    }

    func isMySegmentsEndpoint() -> Bool {
        return url.absoluteString.contains("memberships")
    }

    func isAuthEndpoint() -> Bool {
        return url.absoluteString.contains("auth")
    }

    func isImpressionsEndpoint() -> Bool {
        return url.absoluteString.contains("testImpressions/bulk")
    }

    func isImpressionsCountEndpoint() -> Bool {
        return url.absoluteString.contains("testImpressions/count")
    }

    func isUniqueKeysEndpoint() -> Bool {
        return url.absoluteString.contains("keys/cs")
    }

    func isEventsEndpoint() -> Bool {
        return url.absoluteString.contains("events/bulk")
    }

    func isTelemetryConfigEndpoint() -> Bool {
        return url.absoluteString.contains("metrics/config")
    }

    func isTelemetryUsageEndpoint() -> Bool {
        return url.absoluteString.contains("metrics/usage")
    }
}
