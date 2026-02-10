//
//  HttpClient.swift
//  Http
//

import Foundation

/// Main HTTP client: sends data and stream requests.
public protocol HttpClient: Sendable {
    func sendRequest(endpoint: HttpEndpoint, parameters: HttpParameters?, headers: [String: String]?, body: Data?) throws -> HttpDataRequest
    func sendStreamRequest(endpoint: HttpEndpoint, parameters: HttpParameters?, headers: [String: String]?) throws -> HttpStreamRequest
}

extension HttpClient {
    public func sendRequest(
        endpoint: HttpEndpoint,
        parameters: HttpParameters? = nil,
        headers: [String: String]? = nil
    ) throws -> HttpDataRequest {
        try sendRequest(endpoint: endpoint, parameters: parameters, headers: headers, body: nil)
    }
}

// MARK: - DefaultHttpClient
public class DefaultHttpClient: @unchecked Sendable {
    #if swift(>=6.0)
    nonisolated(unsafe) public static let shared: HttpClient = DefaultHttpClient()
    #else
    public static let shared: HttpClient = DefaultHttpClient()
    #endif

    private var testSession: HttpSession?
    private var testRequestManager: HttpRequestManager?

    private var httpSession: HttpSession!
    private var requestManager: HttpRequestManager!
    private var configuration: HttpSessionConfig
    private var isStarted = false
    private var startQueue = DispatchQueue(label: "http-client-start", target: DispatchQueue.global())

    public init(
        configuration: HttpSessionConfig = HttpSessionConfig.default,
        session: HttpSession? = nil,
        requestManager: HttpRequestManager? = nil
    ) {
        self.configuration = configuration
        self.testSession = session
        self.testRequestManager = requestManager
    }

    public func startIfNeeded() {
        startQueue.sync {
            guard !isStarted else { return }
            let urlSessionConfig = URLSessionConfiguration.default
            urlSessionConfig.timeoutIntervalForRequest = configuration.connectionTimeOut

            if let rm = testRequestManager {
                requestManager = rm
            } else {
                requestManager = DefaultHttpRequestManager(authChallengeHandler: configuration.authChallengeHandler)
            }

            if let session = testSession {
                httpSession = session
            } else {
                let delegate = requestManager as? URLSessionDelegate
                httpSession = DefaultHttpSession(urlSession: URLSession(
                    configuration: urlSessionConfig,
                    delegate: delegate,
                    delegateQueue: nil
                ))
            }
            isStarted = true
        }
    }

    deinit {
        requestManager?.destroy()
        httpSession?.finalize()
    }
}

// MARK: - DefaultHttpClient - Private
extension DefaultHttpClient {
    private func createRequest(
        _ url: URL,
        method: HttpMethod = .get,
        parameters: HttpParameters? = nil,
        headers: HttpHeaders? = nil,
        body: Data? = nil
    ) throws -> HttpDataRequest {
        startIfNeeded()
        return try DefaultHttpDataRequest(
            session: httpSession,
            url: url,
            method: method,
            parameters: parameters,
            headers: headers,
            body: body
        )
    }

    private func createStreamRequest(
        _ url: URL,
        parameters: HttpParameters? = nil,
        headers: HttpHeaders? = nil
    ) throws -> HttpStreamRequest {
        startIfNeeded()
        return try DefaultHttpStreamRequest(
            session: httpSession,
            url: url,
            parameters: parameters,
            headers: headers
        )
    }
}

// MARK: - DefaultHttpClient - HttpClient
extension DefaultHttpClient: HttpClient {
    public func sendRequest(
        endpoint: HttpEndpoint,
        parameters: HttpParameters?,
        headers: [String: String]?,
        body: Data?
    ) throws -> HttpDataRequest {
        var httpHeaders = endpoint.headers
        if let headers = headers {
            for (k, v) in headers { httpHeaders[k] = v }
        }
        let request = try createRequest(
            endpoint.url,
            method: endpoint.method,
            parameters: parameters,
            headers: httpHeaders,
            body: body
        )
        request.send()
        requestManager.addRequest(request)
        return request
    }

    public func sendStreamRequest(
        endpoint: HttpEndpoint,
        parameters: HttpParameters?,
        headers: [String: String]?
    ) throws -> HttpStreamRequest {
        let request = try createStreamRequest(endpoint.url, parameters: parameters, headers: headers)
        request.send()
        requestManager.addRequest(request)
        return request
    }
}
