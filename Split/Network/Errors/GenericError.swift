//
// HttpError.swift
// Split
//
// Created by Javier L. Avrudsky on 04/06/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

enum GenericError: Error {
    case couldNotCreateCache
    case apiKeyNull
    case nullValueInApiFacade
    case jsonParsingFail
    case unknown(message: String)
}

// MARK: Get message
extension GenericError {
    var message: String {
        switch self {
        case .couldNotCreateCache:
            return "Error creating cache db"
        case .apiKeyNull:
            return "ApiKey is null. Please provide a valid one"
        case .nullValueInApiFacade:
            return "Some parameter is null when creating Split Api Facade"
        case .jsonParsingFail:
            return "Something has occured while parsing json data"
        case .unknown(let message):
            return message
        }
    }
}
