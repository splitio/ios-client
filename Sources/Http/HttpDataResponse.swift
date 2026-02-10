//
//  HttpDataResponse.swift
//  Http
//

import Foundation

/// Generic HTTP result for decoded responses.
public enum HttpResult<Value: Sendable>: Sendable {
    case success(Value)
    case failure(Error)

    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    public var isFailure: Bool { !isSuccess }

    public var value: Value? {
        if case .success(let v) = self { return v }
        return nil
    }

    public var error: Error? {
        if case .failure(let e) = self { return e }
        return nil
    }
}

/// Typed data response (e.g. after decoding).
public struct HttpDataResponse<Value: Sendable>: Sendable {
    public var error: Error? { result.error }
    public let data: Data?
    public let result: HttpResult<Value>

    public init(data: Data?, result: HttpResult<Value>) {
        self.data = data
        self.result = result
    }
}
