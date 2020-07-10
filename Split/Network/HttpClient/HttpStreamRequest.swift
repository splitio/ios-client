//
// HttpStreamRequest.swift
// Split
//
// Created by Javier L. Avrudsky on 04/06/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

protocol HttpStreamRequest: HttpRequest {
    typealias ResponseHandler = (HttpResponse) -> Void
    typealias IncomingDataHandler = (Data) -> Void
    typealias CloseHandler = () -> Void

    func getResponse(responseHandler: @escaping ResponseHandler,
                     incomingDataHandler: @escaping IncomingDataHandler,
                     closeHandler: @escaping CloseHandler) -> Self
}

// MARK: HttpStreamRequest
class DefaultHttpStreamRequest: BaseHttpRequest, HttpStreamRequest {

    var responseHandler: ResponseHandler?
    var incomingDataHandler: IncomingDataHandler?
    var closeHandler: CloseHandler?

    init(session: HttpSession, url: URL, parameters: HttpParameters?, headers: HttpHeaders?) throws {
        try super.init(session: session, url: url, method: .get, parameters: parameters, headers: headers)
    }

    override func notifyIncomingData(_ data: Data) {
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

    override func setResponse(code: Int) {
        if let responseHandler  = self.responseHandler {
            responseHandler(HttpResponse(code: code))
        }
    }

    override func complete(error: HttpError?) {
        if let error = error, let errorHandler = self.requestErrorHandler {
            errorHandler(error)
        } else if let closeHandler = self.closeHandler {
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
