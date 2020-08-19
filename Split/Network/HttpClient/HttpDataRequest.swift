//
// HttpDataRequest.swift
// Split
//
// Created by Javier L. Avrudsky on 12/05/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

protocol HttpDataRequest: HttpRequest {
    var data: Data? { get }
    func notifyIncomingData(_ data: Data)
    func getResponse(completionHandler: @escaping RequestCompletionHandler,
                     errorHandler: @escaping RequestErrorHandler) -> Self
}

// MARK: HttpDataRequest
class DefaultHttpDataRequest: BaseHttpRequest, HttpDataRequest {

    private (set) var data: Data?

    override func notifyIncomingData(_ data: Data) {
        if self.data == nil {
            self.data = Data()
        }
        self.data?.append(data)
    }

    func getResponse(completionHandler: @escaping RequestCompletionHandler,
                     errorHandler: @escaping RequestErrorHandler) -> Self {
        self.completionHandler = completionHandler
        self.errorHandler = errorHandler
        return self
    }

    override func complete(error: HttpError?) {
        if let error = error, let errorHandler = errorHandler {
            errorHandler(error)
        } else if let completionHandler = completionHandler {
            completionHandler(HttpResponse(code: responseCode, data: data))
        }
    }
}
