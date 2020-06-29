//
// HttpStreamRequest.swift
// Split
//
// Created by Javier L. Avrudsky on 04/06/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

protocol HttpStreamRequest {
    typealias ResponseHandler = (HttpResponse) -> Void
    typealias IncomingDataHandler = (Data) -> Void
    typealias CloseHandler = () -> Void

    func notify(response: HttpResponse)
    func notifyClose()
    func notifyIncomingData(_ data: Data)
    func getResponse(responseHandler: @escaping ResponseHandler,
                     incomingDataHandler: @escaping IncomingDataHandler,
                     closeHandler: @escaping CloseHandler) -> Self
}

// MARK: HttpStreamRequest
class DefaultHttpStreamRequest: BaseHttpRequestWrapper, HttpStreamRequest {

    var responseHandler: ResponseHandler?
    var incomingDataHandler: IncomingDataHandler?
    var closeHandler: CloseHandler?

    init(session: HttpSessionWrapper, url: URL, parameters: HttpParameters?, headers: HttpHeaders?) throws {
        try super.init(session: session, url: url, method: .get, parameters: parameters, headers: headers)

        self.url = url
        if let headers = headers {
            self.headers = headers
        }
    }

    func notifyIncomingData(_ data: Data) {
        if let incomingDataHandler = self.incomingDataHandler {
            incomingDataHandler(data)
        }
    }

    @discardableResult
    func response(
        queue: DispatchQueue? = nil,
        responseHandler: @escaping ResponseHandler,
        incomingDataHandler: @escaping IncomingDataHandler,
        closeHandler: @escaping CloseHandler) -> Self {
        self.responseHandler = responseHandler
        self.incomingDataHandler = incomingDataHandler
        self.closeHandler = closeHandler
        return self
    }

    func getResponse(responseHandler: @escaping ResponseHandler,
                     incomingDataHandler: @escaping IncomingDataHandler,
                     closeHandler: @escaping CloseHandler) -> Self {

        return response(
            queue: DispatchQueue(label: HttpQueue.default),
            responseHandler: responseHandler,
            incomingDataHandler: incomingDataHandler,
            closeHandler: closeHandler)
    }

    func notify(response: HttpResponse) {
        if let responseHandler = self.responseHandler {
            responseHandler(response)
        }
    }

    func notifyClose() {
        if let closeHandler = self.closeHandler {
            closeHandler()
        }
    }
}

extension DefaultHttpStreamRequest: CustomStringConvertible, CustomDebugStringConvertible {
    private var requestIsNullText: String {
        return "No description available: Null"
    }

    var description: String {
        return urlRequest?.description ?? requestIsNullText
    }

    var debugDescription: String {
        return urlRequest?.debugDescription ?? requestIsNullText
    }
}
