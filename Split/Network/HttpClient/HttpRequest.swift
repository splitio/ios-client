//
//  HttpRequest.swift
//  Split
//
//  Created by Javier L. Avrudsky on 5/23/18.
//

import Foundation

// MARK: HttpDataRequest

protocol HttpRequestProtocol {

    typealias RequestCompletionHandler = () -> Void
    var identifier: Int { get }
    var url: URL { get set }
    var method: HttpMethod { get set }
    var parameters: HttpParameters? { get set }
    var headers: HttpHeaders { get set }
    var response: HTTPURLResponse? { get }
    var retryTimes: Int { get set }

    func setResponse(_ response: HTTPURLResponse)
    func send()
    func retry()
    func complete(withError error: Error?)

}

protocol HttpDataRequestProtocol {
    var data: Data? { get }
    func appendData(_ newData: Data)
}

class HttpRequest: HttpRequestProtocol {

    var httpSession: HttpSession
    var task: URLSessionTask!
    var request: URLRequest!
    var response: HTTPURLResponse?
    var error: Error?
    var retryTimes: Int = 0

    var url: URL
    var method: HttpMethod
    var parameters: HttpParameters?
    var headers: HttpHeaders = [:]

    var requestCompletionHandler: RequestCompletionHandler?

    var identifier: Int {
        return task.taskIdentifier
    }

    init(session: HttpSession, url: URL, method: HttpMethod,
         parameters: HttpParameters? = nil, headers: HttpHeaders?) {
        self.httpSession = session
        self.url = url
        self.method = method
        self.parameters = parameters
        if let headers = headers {
            self.headers = headers
        }
    }

    func send() {
        assertionFailure("Method not implemented")
    }

    func retry() {
        assertionFailure("Method not implemented")
    }

    func setResponse(_ response: HTTPURLResponse) {
        self.response = response
    }

    func complete(withError error: Error?) {
        self.error = error
        if let completionHandler = requestCompletionHandler {
            completionHandler()
        }
    }
}

// MARK: HttpDataRequest
class HttpDataRequest: HttpRequest, HttpDataRequestProtocol {

    var data: Data?
    var body: Data?

    init(session: HttpSession,
         url: URL,
         method: HttpMethod,
         parameters: HttpParameters? = nil,
         headers: HttpHeaders?,
         body: Data? = nil) {

        super.init(session: session, url: url, method: method, parameters: nil, headers: headers)
        self.httpSession = session
        self.url = url
        self.method = method
        self.body = body
        if let headers = headers {
            self.headers = headers
        }
    }

    override func send() {
        request = URLRequest(url: url)
        request.httpMethod = self.method.rawValue

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if method.isUpload, let body = self.bodyPayload() {
            task = httpSession.uploadTask(with: request, from: body)
        } else {
            task = httpSession.dataTask(with: request)
        }
        task.resume()
    }

    func appendData(_ newData: Data) {
        if data == nil {
            data = Data()
        }
        data!.append(newData)
    }

    @discardableResult
    public func response(
        queue: DispatchQueue? = nil,
        responseSerializer: HttpDataResponseSerializer<JSON>,
        completionHandler: @escaping (HttpDataResponse<JSON>) -> Void)
        -> Self {
        requestCompletionHandler = {
            [weak self] in

            guard let strongSelf = self else { return }
            let result = responseSerializer.serializeResponse(strongSelf.request,
                                                              strongSelf.response,
                                                              strongSelf.data,
                                                              strongSelf.error)
            let dataResponse = HttpDataResponse<JSON>(
                request: strongSelf.request, response: strongSelf.response, data: strongSelf.data, result: result
            )
            (queue ?? DispatchQueue.main).async { completionHandler(dataResponse) }
        }

        return self
    }
}

// MARK: HttpDataRequest - RestClientRequestProtocol
extension HttpDataRequest: RestClientRequestProtocol {

    static func responseSerializer(errorSanitizer: @escaping (JSON, Int) -> HttpResult<JSON>)
        -> HttpDataResponseSerializer<JSON> {

        return HttpDataResponseSerializer<JSON> { _, response, data, error in
            if let error = error {
                return .failure(error)
            }

            if let validData = data {
                let json = JSON(validData)
                return errorSanitizer(json, response!.statusCode)
            } else {
                return errorSanitizer(JSON(), response!.statusCode)
            }
        }
    }

    func getResponse(errorSanitizer: @escaping (JSON, Int) -> HttpResult<JSON>,
                     completionHandler: @escaping (HttpDataResponse<JSON>) -> Void) -> Self {

        self.response(
            queue: DispatchQueue(label: HttpQueue.default),
            responseSerializer: HttpDataRequest.responseSerializer(errorSanitizer: errorSanitizer)) { response in
            completionHandler(response)
        }
        return self
    }

}

// MARK: HttpDataRequest - Private

extension HttpDataRequest {
    private func bodyPayload() -> Data? {

        if let body = self.body {
            return body
        }

        if let parameters = parameters,
            let body = try? JSONSerialization.data(withJSONObject: parameters, options: []) {
            return body
        }
        return nil
    }
}

extension HttpDataRequest: CustomStringConvertible, CustomDebugStringConvertible {
    var description: String {
        return request.description
    }

    var debugDescription: String {
        return request.debugDescription
    }

}
