//
// HttpError.swift
// Split
//
// Created by Javier L. Avrudsky on 04/06/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

enum HttpError: Error {
    case clientRelated
    case couldNotCreateRequest(message: String)
    case unknown(message: String)
}

// MARK: Get message
extension HttpError {
    var message: String {
        switch self {
        case .clientRelated:
            return "Authentication error"
        case .couldNotCreateRequest(let message):
            return message
        case .unknown(let message):
            return message
        }
    }
}
