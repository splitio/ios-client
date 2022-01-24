//
// HttpError.swift
// Split
//
// Created by Javier L. Avrudsky on 04/06/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

enum HttpError: Error {
    case serverUnavailable
    case requestTimeOut
    case clientRelated(code: Int)
    case couldNotCreateRequest(message: String)
    case unknown(code: Int, message: String)
}

// MARK: Get message
extension HttpError {
    var code: Int {
        switch self {
        case .clientRelated(let code):
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
        }
    }
}
