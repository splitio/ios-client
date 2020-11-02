//
//  HttpStreamResponse.swift
//  Split
//
//  Created by Javier L. Avrudsky on 4/06/20.

import Foundation

// MARK: HttpStreamResponse
struct HttpStreamResponse {
    let response: HTTPURLResponse?
    let error: Error? = nil
    let data: Data?
    let result: HttpResult<Void>

    init(response: HTTPURLResponse?, data: Data?, result: HttpResult<Void>) {
        self.response = response
        self.data = data
        self.result = result
    }
}
