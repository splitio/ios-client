//
// HttpError.swift
// Split
//
// Created by Javier L. Avrudsky on 04/06/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

enum GenericError: Error {
    case unknown(message: String)
}

// MARK: Get message
extension GenericError {
    var message: String {
        switch self {
        case .unknown(let message):
            return message
        }
    }
}
