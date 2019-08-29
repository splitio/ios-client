//
//  HttpClient.swift
//  Split
//
//  Created by Javier L. Avrudsky on 5/23/18.
//

import Foundation

struct HttpQueue {
    public static let `default`:String = "split-rest-queue"
}

// MARK: HttpMethod
enum HttpMethod: String, CustomStringConvertible {
    case get
    case post
    case patch
    case put
    case delete
    case options
    case head

    public var isUpload: Bool {
        switch self {
        case .post, .patch, .put:
            return true
        default:
            return false
        }
    }

    public var description: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .patch:
            return "PATCH"
        case .put:
            return "PUT"
        case .delete:
            return "DELETE"
        case .options:
            return "OPTIONS"
        case .head:
            return "HEAD"
        }
    }
}

// MARK: HttpSession Delegate
typealias HttpParameters = [String: Any]
typealias HttpHeaders = [String: String]
