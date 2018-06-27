//
//  HttpSession.swift
//  Split
//
//  Created by Javier L. Avrudsky on 5/23/18.

import Foundation

// MARK: HttpSession

class HttpSession {
    
    static let shared: HttpSession = {
        return HttpSession()
    }()
    
    var urlSession: URLSession
    var requestManager: HttpRequestManager
    
    init(configuration: URLSessionConfiguration = URLSessionConfiguration.default) {
        
        if #available(iOS 11.0, *) {
            configuration.waitsForConnectivity = true
        }
        configuration.httpMaximumConnectionsPerHost = 100
        
        requestManager = HttpRequestManager()
        urlSession = URLSession(configuration: configuration,
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
        -> HttpDataRequest
    {
        let request = HttpDataRequest(session: self, url: url, method: method, parameters: parameters, headers: headers, body: body)
        
        return request
    }
    
}

// MARK: HttpSession - RestClientManagerProtocol

extension HttpSession: RestClientManagerProtocol {
    
    func sendRequest(target: Target, parameters: [String : AnyObject]? = nil, headers: [String : String]? = nil) -> RestClientRequestProtocol {
        var httpHeaders = [String:String]()
        if let targetSpecificHeaders = target.commonHeaders {
            httpHeaders += targetSpecificHeaders
        }
        if let headers = headers {
            httpHeaders += headers
        }
        
        let request = self.request(target.url, method: target.method, parameters: parameters, headers: httpHeaders, body: target.body)
        request.send()
        requestManager.addRequest(request)
        return request
    }
}

class HttpRequestManager: NSObject {
    
    var requests = [Int: HttpRequestProtocol]()
    
    func addRequest(_ request: HttpRequestProtocol){
        requests[request.identifier] = request
    }
    
}

// MARK: HttpRequestManager - URLSessionTaskDelegate

extension HttpRequestManager: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?){
        if let request = requests[task.taskIdentifier] {
            request.complete(withError: error)
        }
        requests.removeValue(forKey: task.taskIdentifier)
    }
}

// MARK: HttpUrlSessionDelegate - URLSessionDataDelegate

extension HttpRequestManager: URLSessionDataDelegate {
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void){
        
        if let request = requests[dataTask.taskIdentifier], let response = response as? HTTPURLResponse {
            request.setResponse(response)
            completionHandler(.allow)
        } else {
            completionHandler(.cancel)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let request = requests[dataTask.taskIdentifier] as? HttpDataRequestProtocol {
            request.appendData(data)
        }
    }
}
