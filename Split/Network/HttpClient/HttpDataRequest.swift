//
// HttpDataRequest.swift
// Split
//
// Created by Javier L. Avrudsky on 12/05/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

protocol HttpDataRequestWrapper: HttpRequest {
    var data: Data? { get }
    func notifyIncomingData(_ data: Data)
    func getResponse(completionHandler: @escaping RequestCompletionHandler,
                     errorHandler: @escaping RequestErrorHandler) -> Self
}

// MARK: HttpDataRequest
class DefaultHttpDataRequestWrapper: BaseHttpRequest, HttpDataRequestWrapper {

    var data: Data?

    override func notifyIncomingData(_ data: Data) {
        if self.data == nil {
            self.data = Data()
        }
        self.data?.append(data)
    }

    func getResponse(completionHandler: @escaping RequestCompletionHandler,
                     errorHandler: @escaping RequestErrorHandler) -> Self {
        requestCompletionHandler = completionHandler
        requestErrorHandler = errorHandler
        return self
    }

    override func complete(error: HttpError?) {
        if let error = error, let errorHandler = requestErrorHandler {
            errorHandler(error)
        } else if let completionHandler = requestCompletionHandler {
            completionHandler(HttpResponse(code: responseCode, data: data))
        }
    }
}
