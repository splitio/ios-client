//
//  HttpResponse.swift
//  Split
//
//  Created by Javier L. Avrudsky on 25/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

// MARK: HttpResponse

/// Stands a base clase for Http responses
/// It has a http error code and a default error check based on
/// Http response code
struct HttpResponse {
    let code: Int
    let result: HttpResultWrapper
    let internalCode: Int // InternalHttpErrorCode
    var isClientError: Bool {
        return code >= HttpCode.badRequest && code < HttpCode.internalServerError
    }

    init(code: Int, data: Data? = nil, internalCode: Int = InternalHttpErrorCode.noCode) {
        self.code = code
        self.internalCode = internalCode
        if code >= HttpCode.requestOk, code < HttpCode.multipleChoice {
            self.result = HttpResultWrapper.success(Json(data))
        } else {
            self.result = HttpResultWrapper.failure
        }
    }
}
