//
//  HttpClient.swift
//  Split
//
//  Created by Javier L. Avrudsky on 5/23/18.

import Foundation

// MARK: HttpSession

/// HttpClient is main wrapper component to handle HTTP activity
/// This file also includes some complementary HTTP client components
///
enum HttpQueue {
    public static let `default`: String = "split-rest-queue"
}

// MARK: HTTP codes

enum HttpCode {
    static let requestOk = 200
    static let multipleChoice = 300
    static let badRequest = 400
    static let unauthorized = 401
    static let forbidden = 403
    static let notFound = 404
    static let requestTimeOut = 408
    static let uriTooLong = 414
    static let internalServerError = 500
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
        case .patch, .post, .put:
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

typealias HttpHeaders = [String: String]

class HttpSessionConfig {
    static let kDefaultConnectionTimeout: TimeInterval = 30

    static let `default`: HttpSessionConfig = {
        HttpSessionConfig()
    }()

    var connectionTimeOut: TimeInterval = kDefaultConnectionTimeout
    var httpsAuthenticator: SplitHttpsAuthenticator?
    var pinChecker: TlsPinChecker?
    var notificationHelper: NotificationHelper?
}

protocol HttpClient {
    func sendRequest(
        endpoint: Endpoint,
        parameters: HttpParameters?,
        headers: [String: String]?,
        body: Data?) throws -> HttpDataRequest

    func sendStreamRequest(
        endpoint: Endpoint,
        parameters: HttpParameters?,
        headers: [String: String]?) throws -> HttpStreamRequest
}

extension HttpClient {
    func sendRequest(
        endpoint: Endpoint,
        parameters: HttpParameters? = nil,
        headers: [String: String]? = nil) throws -> HttpDataRequest {
        return try sendRequest(endpoint: endpoint, parameters: parameters, headers: headers, body: nil)
    }
}

class DefaultHttpClient {
    static let shared: HttpClient = {
        DefaultHttpClient()
    }()

    private var testSession: HttpSession?
    private var testRequestManager: HttpRequestManager?

    private var httpSession: HttpSession!
    private var requestManager: HttpRequestManager!
    private var configuration: HttpSessionConfig
    private var isStarted = false
    private var startQueue = DispatchQueue(label: "http-client-start", target: DispatchQueue.general)

    init(
        configuration: HttpSessionConfig = HttpSessionConfig.default,
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
                    self.requestManager = DefaultHttpRequestManager(
                        authententicator: configuration.httpsAuthenticator,
                        pinChecker: configuration.pinChecker,
                        notificationHelper: configuration
                            .notificationHelper)
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
    private func createRequest(
        _ url: URL,
        method: HttpMethod = .get,
        parameters: HttpParameters? = nil,
        headers: HttpHeaders? = nil,
        body: Data? = nil) throws -> HttpDataRequest {
        startIfNeeded()
        let request = try DefaultHttpDataRequest(
            session: httpSession,
            url: url,
            method: method,
            parameters: parameters,
            headers: headers,
            body: body)
        return request
    }

    private func createStreamRequest(
        _ url: URL,
        parameters: HttpParameters? = nil,
        headers: HttpHeaders? = nil) throws -> HttpStreamRequest {
        startIfNeeded()
        let request = try DefaultHttpStreamRequest(
            session: httpSession,
            url: url,
            parameters: parameters,
            headers: headers)
        return request
    }
}

// MARK: DefaultHttpClient - HttpClient

extension DefaultHttpClient: HttpClient {
    func sendRequest(
        endpoint: Endpoint,
        parameters: HttpParameters?,
        headers: [String: String]?,
        body: Data?) throws -> HttpDataRequest {
        var httpHeaders = endpoint.headers
        if let headers = headers {
            httpHeaders += headers
        }

        let request = try createRequest(
            endpoint.url,
            method: endpoint.method,
            parameters: parameters,
            headers: httpHeaders,
            body: body)
        request.send()
        requestManager.addRequest(request)
        return request
    }

    func sendStreamRequest(
        endpoint: Endpoint,
        parameters: HttpParameters?,
        headers: [String: String]?) throws -> HttpStreamRequest {
        let request = try createStreamRequest(endpoint.url, parameters: parameters, headers: headers)
        request.send()
        requestManager.addRequest(request)
        return request
    }
}
