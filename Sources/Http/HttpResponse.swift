//
//  HttpResponse.swift
//  Http
//

import Foundation

/// Result wrapper for HTTP body (raw data; no JSON dependency).
public enum HttpResultWrapper: Sendable {
    case success(Data?)
    case failure

    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    public var value: Data? {
        if case .success(let data) = self { return data }
        return nil
    }
}

/// HTTP response: status code, body result, optional internal error code.
public struct HttpResponse: Sendable {
    public let code: Int
    public let result: HttpResultWrapper
    public let internalCode: Int

    public var isClientError: Bool {
        code >= HttpCode.badRequest && code < HttpCode.internalServerError
    }

    public init(code: Int, data: Data? = nil, internalCode: Int = InternalHttpErrorCode.noCode) {
        self.code = code
        self.internalCode = internalCode
        if code >= HttpCode.requestOk && code < HttpCode.multipleChoice {
            self.result = .success(data)
        } else {
            self.result = .failure
        }
    }
}
