//
// HttpDataRequest.swift
// Http
//
// Created by Javier L. Avrudsky on 12/05/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

public protocol HttpDataRequest: HttpRequest, HttpDataReceivingRequest {
    var data: Data? { get }
    func notifyIncomingData(_ data: Data)
    func getResponse(completionHandler: @escaping RequestCompletionHandler,
                     errorHandler: @escaping RequestErrorHandler) -> Self
}

// MARK: HttpDataRequest
public class DefaultHttpDataRequest: BaseHttpRequest, HttpDataRequest, @unchecked Sendable {

    public private(set) var data: Data?

    override public func notifyIncomingData(_ data: Data) {
        if self.data == nil {
            self.data = Data()
        }
        self.data?.append(data)
    }

    public func getResponse(completionHandler: @escaping RequestCompletionHandler,
                     errorHandler: @escaping RequestErrorHandler) -> Self {
        requestQueue.sync {
            self.completionHandler = completionHandler
            self.errorHandler = errorHandler
        }
        return self
    }

    override public func complete(error: HttpError?) {
        requestQueue.async(flags: .barrier) {
            var internalCode = InternalHttpErrorCode.noCode
            if self.pinnedCredentialFail {
                internalCode = InternalHttpErrorCode.pinningValidationFail
            }

            if let error = error, let errorHandler = self.errorHandler {
                if internalCode == InternalHttpErrorCode.pinningValidationFail {
                    errorHandler(.clientRelated(code: error.code, internalCode: internalCode))
                    return
                }
                errorHandler(error)
            } else if let completionHandler = self.completionHandler {
                completionHandler(HttpResponse(code: self.responseCode,
                                               data: self.data,
                                               internalCode: internalCode)
                )
            }
        }
    }
}
