//
// HttpStreamRequest.swift
// Split
//
// Created by Javier L. Avrudsky on 04/06/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

protocol HttpStreamRequest: HttpRequest, HttpDataReceivingRequest {
    typealias ResponseHandler = (HttpResponse) -> Void
    typealias IncomingDataHandler = (Data) -> Void
    typealias CloseHandler = () -> Void
    typealias ErrorHandler = (HttpError) -> Void

    func getResponse(responseHandler: @escaping ResponseHandler,
                     incomingDataHandler: @escaping IncomingDataHandler,
                     closeHandler: @escaping CloseHandler,
                     errorHandler: @escaping ErrorHandler) -> Self

    func close()
}

// MARK: DefaultHttpStreamRequest
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
        closeHandler: @escaping CloseHandler,
        errorHandler: @escaping ErrorHandler) -> Self {
        self.responseHandler = responseHandler
        self.incomingDataHandler = incomingDataHandler
        self.closeHandler = closeHandler
        self.errorHandler = errorHandler
        return self
    }

    func getResponse(responseHandler: @escaping ResponseHandler, incomingDataHandler: @escaping IncomingDataHandler,
                     closeHandler: @escaping CloseHandler, errorHandler: @escaping ErrorHandler) -> Self {

        return response(
            queue: DispatchQueue(label: HttpQueue.default),
            responseHandler: responseHandler,
            incomingDataHandler: incomingDataHandler,
            closeHandler: closeHandler,
            errorHandler: errorHandler)
    }

    func close() {
        task?.cancel()
    }

    override func setResponse(code: Int) {
        if let responseHandler  = self.responseHandler {
            responseHandler(HttpResponse(code: code))
        }
    }

    override func complete(error: HttpError?) {
        if let error = error, let errorHandler = self.errorHandler {
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
