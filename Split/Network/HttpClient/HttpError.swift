//
// HttpError.swift
// Split
//
// Created by Javier L. Avrudsky on 04/06/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

enum InternalHttpErrorCode {
    static let pinningValidationFail = 1
    static let noCode = -1
}

enum HttpError: Error, Equatable {
    case serverUnavailable
    case requestTimeOut
    case uriTooLong
    case clientRelated(code: Int, internalCode: Int)
    case couldNotCreateRequest(message: String)
    case unknown(code: Int, message: String)
    case outdatedProxyError(code: Int, spec: String)
}

// MARK: Get message

extension HttpError {
    var code: Int {
        switch self {
        case let .clientRelated(code, _):
            return code
        case let .unknown(code, _):
            return code
        case let .outdatedProxyError(code, _):
            return code
        default:
            return -1
        }
    }

    /// Determines if this error is related to an outdated proxy
    /// - Returns: true if this is an outdated proxy error, false otherwise
    func isProxyOutdatedError() -> Bool {
        switch self {
        case .outdatedProxyError:
            return true
        default:
            return false
        }
    }

    var message: String {
        switch self {
        case .serverUnavailable:
            return "Server is unavailable"
        case .clientRelated:
            return "Authentication error"
        case let .couldNotCreateRequest(message):
            return message
        case let .unknown(_, message):
            return message
        case .requestTimeOut:
            return "Request Time Out"
        case .uriTooLong:
            return "Uri too long"
        case let .outdatedProxyError(code, spec):
            return "Outdated proxy error with spec version \(spec) (HTTP \(code))"
        }
    }

    var internalCode: Int {
        switch self {
        case let .clientRelated(_, internalCode):
            return internalCode
        default:
            return InternalHttpErrorCode.noCode
        }
    }
}
