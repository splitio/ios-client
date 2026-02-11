//
//  HttpResponse.swift
//  Http
//
//  Created by Javier L. Avrudsky on 25/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

// MARK: HttpResponse
/// Stands a base class for Http responses
/// It has a http error code and a default error check based on
/// Http response code
public struct HttpResponse {
    public let code: Int
    public let data: Data?
    let internalCode: Int // InternalHttpErrorCode

    public var isSuccess: Bool {
        code >= HttpCode.requestOk && code < HttpCode.multipleChoice
    }

    public var isClientError: Bool {
        code >= HttpCode.badRequest && code < HttpCode.internalServerError
    }

    public init(code: Int, data: Data? = nil, internalCode: Int = InternalHttpErrorCode.noCode) {
        self.code = code
        self.data = data
        self.internalCode = internalCode
    }
}
