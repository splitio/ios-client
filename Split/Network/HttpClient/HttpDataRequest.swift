//
// HttpDataRequest.swift
// Split
//
// Created by Javier L. Avrudsky on 12/05/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

protocol HttpDataRequest: HttpRequest, HttpDataReceivingRequest {
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
        requestQueue.sync {
            self.completionHandler = completionHandler
            self.errorHandler = errorHandler
        }
        return self
    }

    override func complete(error: HttpError?) {
        requestQueue.async(flags: .barrier) {
            if let error = error, let errorHandler = self.errorHandler {
                errorHandler(error)
            } else if let completionHandler = self.completionHandler {
                completionHandler(HttpResponse(code: self.responseCode, data: self.data))
            }
        }
    }
}
