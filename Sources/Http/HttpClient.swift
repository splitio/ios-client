//
//  HttpClient.swift
//  Http
//
//  Created by Javier L. Avrudsky on 5/23/18.

import Foundation
#if !COCOAPODS
import Logging
#endif

private func += <K, V> ( left: inout [K: V], right: [K: V]) {
    for (key, value) in right {
        left[key] = value
    }
}

// MARK: HttpSession

/// HttpClient is main wrapper component to handle HTTP activity
/// This file also includes some complementary HTTP client components
///
struct HttpQueue {
    static let `default`: String = "split-rest-queue"
}

// MARK: HTTP codes
public struct HttpCode {
    static let requestOk = 200
    static let multipleChoice = 300
    public static let badRequest = 400
    static let unauthorized = 401
    static let forbidden = 403
    static let notFound = 404
    static let requestTimeOut = 408
    public static let uriTooLong = 414
    public static let internalServerError = 500
    public static let networkLost = -1005
}

// MARK: HttpMethod
public enum HttpMethod: String, CustomStringConvertible {
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
public typealias HttpHeaders = [String: String]

public class HttpSessionConfig: @unchecked Sendable {
    static let kDefaultConnectionTimeout: TimeInterval = 30

    public static let `default`: HttpSessionConfig = {
        HttpSessionConfig()
    }()
    public var connectionTimeOut: TimeInterval = kDefaultConnectionTimeout
    public var authenticator: HttpAuthenticator?
    public var pinChecker: TlsPinChecker?
    public var notificationHandler: HttpNotificationHandler?

    public init() {}
}

public protocol HttpClient {

    func sendRequest(endpoint: Endpoint, parameters: HttpParameters?,
                     headers: [String: String]?, body: Data?) throws -> HttpDataRequest

    func sendStreamRequest(endpoint: Endpoint, parameters: HttpParameters?,
                           headers: [String: String]?) throws -> HttpStreamRequest
}

extension HttpClient {
    public func sendRequest(endpoint: Endpoint, parameters: HttpParameters? = nil,
                     headers: [String: String]? = nil) throws -> HttpDataRequest {
        try sendRequest(endpoint: endpoint, parameters: parameters, headers: headers, body: nil)
    }
}

public class DefaultHttpClient: @unchecked Sendable {

    #if swift(>=6.0)
        nonisolated(unsafe) public static let shared: HttpClient = { DefaultHttpClient() }()
    #else
        public static let shared: HttpClient = { DefaultHttpClient() }()
    #endif
    
    private var testSession: HttpSession?
    private var testRequestManager: HttpRequestManager?

    private var httpSession: HttpSession!
    private var requestManager: HttpRequestManager!
    private var configuration: HttpSessionConfig
    private var isStarted = false
    private var startQueue = DispatchQueue(label: "http-client-start", attributes: .concurrent)

    public init(configuration: HttpSessionConfig = HttpSessionConfig.default,
         session: HttpSession? = nil,
         requestManager: HttpRequestManager? = nil) {

        self.configuration = configuration
        self.testSession = session
        self.testRequestManager = requestManager
    }

    func startIfNeeded() {
        startQueue.sync {
            if !isStarted {
                let urlSessionConfig = URLSessionConfiguration.default

                urlSessionConfig.timeoutIntervalForRequest = configuration.connectionTimeOut

                if let requestManager = testRequestManager {
                    self.requestManager = requestManager
                } else {
                    self.requestManager = DefaultHttpRequestManager(authenticator: configuration.authenticator,
                                                                    pinChecker: configuration.pinChecker,
                                                                    notificationHandler: configuration.notificationHandler)
                }

                if let httpSession = testSession {
                    self.httpSession = httpSession
                } else {
                    let delegate = self.requestManager as? URLSessionDelegate
                    self.httpSession = DefaultHttpSession(urlSession: URLSession(
                        configuration: urlSessionConfig, delegate: delegate, delegateQueue: nil))
                }
                Logger.d("HTTP Client started")
                isStarted = true
            }
        }
    }

    deinit {
        requestManager?.destroy()
        httpSession?.finalize()
    }
}

// MARK: DefaultHttpClient - Private
extension DefaultHttpClient {

    private func createRequest(_ url: URL, method: HttpMethod = .get, parameters: HttpParameters? = nil,
                               headers: HttpHeaders? = nil, body: Data? = nil) throws -> HttpDataRequest {
        startIfNeeded()
        let request = try DefaultHttpDataRequest(session: httpSession, url: url, method: method,
                                                 parameters: parameters, headers: headers, body: body)
        return request
    }

    private func createStreamRequest(_ url: URL, parameters: HttpParameters? = nil,
                                     headers: HttpHeaders? = nil) throws -> HttpStreamRequest {
        startIfNeeded()
        let request = try DefaultHttpStreamRequest(session: httpSession, url: url,
                                                   parameters: parameters, headers: headers)
        return request
    }

}

// MARK: DefaultHttpClient - HttpClient
extension DefaultHttpClient: HttpClient {

    public func sendRequest(endpoint: Endpoint, parameters: HttpParameters?, headers: [String: String]?,
                     body: Data?) throws -> HttpDataRequest {
        var httpHeaders = endpoint.headers
        if let headers = headers {
            httpHeaders += headers
        }

        let request = try self.createRequest(endpoint.url, method: endpoint.method, parameters: parameters,
                                             headers: httpHeaders, body: body)
        request.send()
        requestManager.addRequest(request)
        return request
    }

    public func sendStreamRequest(endpoint: Endpoint, parameters: HttpParameters?,
                           headers: [String: String]?) throws -> HttpStreamRequest {
            let request = try self.createStreamRequest(endpoint.url, parameters: parameters, headers: headers)
        request.send()
        requestManager.addRequest(request)
        return request
    }
}
