//
// HttpError.swift
// Split
//
// Created by Javier L. Avrudsky on 04/06/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

struct InternalHttpErrorCode {
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
}

// MARK: Get message
extension HttpError {
    var code: Int {
        switch self {
        case .clientRelated(let code, _):
            return code
        case .unknown(let code, _):
            return code
        default:
            return -1
        }
    }

    var message: String {
        switch self {
        case .serverUnavailable:
            return "Server is unavailable"
        case .clientRelated:
            return "Authentication error"
        case .couldNotCreateRequest(let message):
            return message
        case .unknown( _, let message):
            return message
        case .requestTimeOut:
            return "Request Time Out"
        case .uriTooLong:
            return "Uri too long"
        }
    }

    var internalCode: Int {
        switch self {
        case .clientRelated(_, let internalCode):
            return internalCode
        default:
            return InternalHttpErrorCode.noCode
        }
    }
}
