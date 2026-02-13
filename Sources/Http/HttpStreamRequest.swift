//
// HttpStreamRequest.swift
// Http
//
// Created by Javier L. Avrudsky on 04/06/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

public protocol HttpStreamRequest: HttpRequest, HttpDataReceivingRequest {
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
public class DefaultHttpStreamRequest: BaseHttpRequest, HttpStreamRequest, @unchecked Sendable {

    public var responseHandler: ResponseHandler?
    public var incomingDataHandler: IncomingDataHandler?
    public var closeHandler: CloseHandler?
    
    public init(session: HttpSession, url: URL, parameters: HttpParameters?, headers: HttpHeaders?) throws {
        try super.init(session: session, url: url, method: .get, parameters: parameters, headers: headers)
    }

    override public func notifyIncomingData(_ data: Data) {
        if let incomingDataHandler = self.incomingDataHandler {
            incomingDataHandler(data)
        }
    }

    @discardableResult
    public func response(
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

    public func getResponse(responseHandler: @escaping ResponseHandler, incomingDataHandler: @escaping IncomingDataHandler,
                     closeHandler: @escaping CloseHandler, errorHandler: @escaping ErrorHandler) -> Self {

        response(
            queue: DispatchQueue(label: HttpQueue.default),
            responseHandler: responseHandler,
            incomingDataHandler: incomingDataHandler,
            closeHandler: closeHandler,
            errorHandler: errorHandler)
    }

    public func close() {
        task?.cancel()
    }

    override public func setResponse(code: Int) {
        if let responseHandler  = self.responseHandler {
            responseHandler(HttpResponse(code: code))
        }
    }

    override public func complete(error: HttpError?) {
        if let error = error, let errorHandler = self.errorHandler {
            errorHandler(error)
        } else if let closeHandler = self.closeHandler {
            closeHandler()
        }
    }
}

extension DefaultHttpStreamRequest: CustomStringConvertible, CustomDebugStringConvertible {
    private var requestIsNullText: String {
        "No description available: Null"
    }

    public var description: String {
        urlRequest?.description ?? requestIsNullText
    }

    public var debugDescription: String {
        urlRequest?.debugDescription ?? requestIsNullText
    }
}
