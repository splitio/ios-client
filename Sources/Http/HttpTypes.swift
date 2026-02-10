//
//  HttpTypes.swift
//  Http
//
//  Core HTTP types: queue name, status codes, method, headers.
//

import Foundation

public struct HttpQueue {
    public static let `default`: String = "split-rest-queue"
}

// MARK: - HTTP status codes
public struct HttpCode {
    public static let requestOk = 200
    public static let multipleChoice = 300
    public static let badRequest = 400
    public static let unauthorized = 401
    public static let forbidden = 403
    public static let notFound = 404
    public static let requestTimeOut = 408
    public static let uriTooLong = 414
    public static let internalServerError = 500
    public static let networkLost = -1005
}

// MARK: - HttpMethod
public enum HttpMethod: String, CustomStringConvertible, Sendable {
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
        case .get: return "GET"
        case .post: return "POST"
        case .patch: return "PATCH"
        case .put: return "PUT"
        case .delete: return "DELETE"
        case .options: return "OPTIONS"
        case .head: return "HEAD"
        }
    }
}

public typealias HttpHeaders = [String: String]
