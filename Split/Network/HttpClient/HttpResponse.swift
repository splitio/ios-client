//
//  HttpResponse.swift
//  Split
//
//  Created by Javier L. Avrudsky on 25/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

/// Stands a base clase for Http responses
/// It has a http error code and a default error check based on
/// Http response code
// MARK: HttpResponse
struct HttpResponse {
    let code: Int

    var isSuccess: Bool {
        return code >= HttpCode.requestOk && code < HttpCode.multipleChoice
    }

    init(code: Int) {
        self.code = code
    }
}
