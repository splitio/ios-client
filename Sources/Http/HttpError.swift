//
//  HttpError.swift
//  Http
//

import Foundation

public struct InternalHttpErrorCode {
    public static let pinningValidationFail = 1
    public static let noCode = -1
}

public enum HttpError: Error, Equatable, Sendable {
    case serverUnavailable
    case requestTimeOut
    case uriTooLong
    case clientRelated(code: Int, internalCode: Int)
    case couldNotCreateRequest(message: String)
    case unknown(code: Int, message: String)
    case outdatedProxyError(code: Int, spec: String)
    case networkLost(code: Int)
}

extension HttpError {
    public var code: Int {
        switch self {
        case .clientRelated(let code, _): return code
        case .unknown(let code, _): return code
        case .outdatedProxyError(let code, _): return code
        case .networkLost(let code): return code
        default: return -1
        }
    }

    public func isProxyOutdatedError() -> Bool {
        if case .outdatedProxyError = self { return true }
        return false
    }

    public var message: String {
        switch self {
        case .serverUnavailable: return "Server is unavailable"
        case .clientRelated: return "Authentication error"
        case .couldNotCreateRequest(let message): return message
        case .unknown(_, let message): return message
        case .requestTimeOut: return "Request Time Out"
        case .uriTooLong: return "Uri too long"
        case .outdatedProxyError(let code, let spec): return "Outdated proxy error with spec version \(spec) (HTTP \(code))"
        case .networkLost: return "Network lost"
        }
    }

    public var internalCode: Int {
        if case .clientRelated(_, let internalCode) = self { return internalCode }
        return InternalHttpErrorCode.noCode
    }
}
