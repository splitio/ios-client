//
//  HttpSession.swift
//  Split
//
//  Created by Javier L. Avrudsky on 5/23/18.

import Foundation

// MARK: HttpSession

class HttpSessionConfig {
    static let  `default`: HttpSessionConfig = {
        return HttpSessionConfig()
    }()
    var connectionTimeOut: TimeInterval = 30
}

class HttpSession {

    static let shared: HttpSession = {
        return HttpSession()
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

    func dataTask(with request: URLRequest) -> URLSessionTask {
        return urlSession.dataTask(with: request)
    }

    func uploadTask(with request: URLRequest,
                    from bodyData: Data) -> URLSessionUploadTask {
        return urlSession.uploadTask(with: request, from: bodyData)
    }
}

// MARK: HttpSession - Private

extension HttpSession {

    private func request(
        _ url: URL,
        method: HttpMethod = .get,
        parameters: HttpParameters? = nil,
        headers: HttpHeaders? = nil,
        body: Data? = nil)
        -> HttpDataRequest {
        let request = HttpDataRequest(session: self,
                                      url: url,
                                      method: method,
                                      parameters: parameters,
                                      headers: headers,
                                      body: body)

        return request
    }

}

// MARK: HttpSession - RestClientManagerProtocol

extension HttpSession: RestClientManagerProtocol {

    func sendRequest(target: Target,
                     parameters: [String: AnyObject]? = nil,
                     headers: [String: String]? = nil) -> RestClientRequestProtocol {
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
    private var requests: [Int: HttpRequestProtocol]

    init() {
        queue = DispatchQueue(label: queueName, attributes: .concurrent)
        requests = [Int: HttpRequestProtocol]()
    }

    func set(_ request: HttpRequestProtocol) {
        queue.async(flags: .barrier) {
            self.requests[request.identifier] = request
        }
    }

    func get(identifier: Int) -> HttpRequestProtocol? {
        var request: HttpRequestProtocol?
        queue.sync {
            request = requests[identifier]
        }
        return request
    }

    func take(identifier: Int) -> HttpRequestProtocol? {
        var request: HttpRequestProtocol?
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

    func addRequest(_ request: HttpRequestProtocol) {
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
        if let request = requests.get(identifier: dataTask.taskIdentifier) as? HttpDataRequestProtocol {
            request.appendData(data)
        }
    }
}
