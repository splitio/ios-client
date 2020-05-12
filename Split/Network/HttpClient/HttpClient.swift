//
//  HttpClient.swift
//  Split
//
//  Created by Javier L. Avrudsky on 5/23/18.

import Foundation

// MARK: HttpSession
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

class HttpSessionConfig {
    static let  `default`: HttpSessionConfig = {
        return HttpSessionConfig()
    }()
    var connectionTimeOut: TimeInterval = 30
}

protocol HttpClient {
    func sendRequest(target: Target,
                     parameters: [String: AnyObject]?,
                     headers: [String: String]?) -> HttpDataRequest
}

extension HttpClient {
    func sendRequest(target: Target,
                     parameters: [String: AnyObject]? = nil) -> HttpDataRequest {
        return sendRequest(target: target, parameters: parameters, headers: nil)
    }
}

protocol HttpSession {
    func dataTask(with request: URLRequest) -> URLSessionTask

    func uploadTask(with request: URLRequest,
                    from bodyData: Data) -> URLSessionUploadTask
}

class DefaultHttpClient {

    static let shared: DefaultHttpClient = {
        return DefaultHttpClient()
    }()

    var urlSession: URLSession
    var requestManager: HttpRequestManager

    init(configuration: HttpSessionConfig = HttpSessionConfig.default) {

        let urlSessionConfig = URLSessionConfiguration.default

        urlSessionConfig.timeoutIntervalForResource = configuration.connectionTimeOut
        urlSessionConfig.timeoutIntervalForRequest = configuration.connectionTimeOut
        urlSessionConfig.httpMaximumConnectionsPerHost = 100

        requestManager = HttpRequestManager()
        urlSession = URLSession(configuration: urlSessionConfig,
                delegate: requestManager, delegateQueue: nil)
    }

    deinit {
        urlSession.invalidateAndCancel()
    }


}

extension DefaultHttpClient: HttpSession {

    func dataTask(with request: URLRequest) -> URLSessionTask {
        return urlSession.dataTask(with: request)
    }

    func uploadTask(with request: URLRequest,
                    from bodyData: Data) -> URLSessionUploadTask {
        return urlSession.uploadTask(with: request, from: bodyData)
    }
}

// MARK: HttpSession - Private

extension DefaultHttpClient {

    private func request(
        _ url: URL,
        method: HttpMethod = .get,
        parameters: HttpParameters? = nil,
        headers: HttpHeaders? = nil,
        body: Data? = nil)
        -> DefaultHttpDataRequest {
        let request = DefaultHttpDataRequest(session: self,
                                      url: url,
                                      method: method,
                                      parameters: parameters,
                                      headers: headers,
                                      body: body)

        return request
    }

}

// MARK: HttpSession - RestClientManagerProtocol

extension DefaultHttpClient: HttpClient {

    func sendRequest(target: Target,
                     parameters: [String: AnyObject]? = nil,
                     headers: [String: String]? = nil) -> HttpDataRequest {
        var httpHeaders = [String: String]()
        if let targetSpecificHeaders = target.commonHeaders {
            httpHeaders += targetSpecificHeaders
        }
        if let headers = headers {
            httpHeaders += headers
        }

        let request = self.request(target.url,
                                   method: target.method,
                                   parameters: parameters,
                                   headers: httpHeaders,
                                   body: target.body)
        request.send()
        requestManager.addRequest(request)
        return request
    }
}

class HttpRequestList {
    private let queueName = "split.http-request-queue"
    private var queue: DispatchQueue
    private var requests: [Int: HttpRequest]

    init() {
        queue = DispatchQueue(label: queueName, attributes: .concurrent)
        requests = [Int: HttpRequest]()
    }

    func set(_ request: HttpRequest) {
        queue.async(flags: .barrier) {
            self.requests[request.identifier] = request
        }
    }

    func get(identifier: Int) -> HttpRequest? {
        var request: HttpRequest?
        queue.sync {
            request = requests[identifier]
        }
        return request
    }

    func take(identifier: Int) -> HttpRequest? {
        var request: HttpRequest?
        queue.sync {
            request = requests[identifier]
            if request != nil {
                queue.async(flags: .barrier) {
                    self.requests.removeValue(forKey: identifier)
                }
            }
        }
        return request
    }
}

class HttpRequestManager: NSObject {

    var requests = HttpRequestList()

    func addRequest(_ request: HttpRequest) {
        requests.set(request)
    }
}

// MARK: HttpRequestManager - URLSessionTaskDelegate

extension HttpRequestManager: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let request = requests.take(identifier: task.taskIdentifier) {
            request.complete(withError: error)
        }
    }
}

// MARK: HttpUrlSessionDelegate - URLSessionDataDelegate

extension HttpRequestManager: URLSessionDataDelegate {
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let request = requests.get(identifier: dataTask.taskIdentifier),
            let response = response as? HTTPURLResponse {
            request.setResponse(response)
            completionHandler(.allow)
        } else {
            completionHandler(.cancel)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let request = requests.get(identifier: dataTask.taskIdentifier) as? HttpDataRequest {
            request.appendData(data)
        }
    }
}
