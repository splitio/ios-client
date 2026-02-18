//  HttpDataResponse
//  Created by Javier L. Avrudsky on 5/23/18.
//  Initially based on Alamofire network library API.
//  Copyright © 2018 Split. All rights reserved.

import Foundation

// MARK: Data Response
struct HttpDataResponse<Value> {
    let error: Error? = nil
    let data: Data?
    let result: HttpResult<Value>

    init(data: Data?, result: HttpResult<Value>) {
        self.data = data
        self.result = result
    }
}

// MARK: Result
enum HttpResult<Value> {
    case success(Value)
    case failure(Error)

    var isSuccess: Bool {
        switch self {
        case .success: true
        case .failure: false
        }
    }

    var isFailure: Bool {
        !isSuccess
    }

    var value: Value? {
        switch self {
        case .success(let value): value
        case .failure: nil
        }
    }

    var error: Error? {
        switch self {
        case .success: nil
        case .failure(let error): error
        }
    }
}
