//
// HttpDataRequest.swift
// Split
//
// Created by Javier L. Avrudsky on 12/05/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation
protocol HttpDataRequest {
    var data: Data? { get }
    func appendData(_ newData: Data)
    func getResponse(errorSanitizer: @escaping (JSON, Int) -> HttpResult<JSON>,
                     completionHandler: @escaping (HttpDataResponse<JSON>) -> Void) -> Self
}

// MARK: HttpDataRequest
class DefaultHttpDataRequest: BaseHttpRequest, HttpDataRequest {

    var data: Data?
    var body: Data?

    init(session: HttpSession,
         url: URL,
         method: HttpMethod,
         parameters: HttpParameters? = nil,
         headers: HttpHeaders?,
         body: Data? = nil) {

        super.init(session: session, url: url, method: method, parameters: nil, headers: headers)
        self.session = session
        self.url = url
        self.method = method
        self.body = body
        if let headers = headers {
            self.headers = headers
        }
    }

    override func send() {

        request = URLRequest(url: url)

        guard var request = self.request else {
            return
        }

        request.httpMethod = self.method.rawValue

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if method.isUpload, let body = self.bodyPayload() {
            task = session.uploadTask(with: request, from: body)
        } else {
            task = session.dataTask(with: request)
        }
        task?.resume()
    }

    func appendData(_ newData: Data) {
        if data == nil {
            data = Data()
        }
        data!.append(newData)
    }

    @discardableResult
    func response(
            queue: DispatchQueue? = nil,
            responseSerializer: HttpDataResponseSerializer<JSON>,
            completionHandler: @escaping (HttpDataResponse<JSON>) -> Void) -> Self {

        requestCompletionHandler = {
            [weak self] in

            guard let strongSelf = self else { return }
            let result = responseSerializer.serializeResponse(strongSelf.request,
                    strongSelf.response,
                    strongSelf.data,
                    strongSelf.error)
            let dataResponse = HttpDataResponse<JSON>(
                    response: strongSelf.response, data: strongSelf.data, result: result
            )
            (queue ?? DispatchQueue.main).async { completionHandler(dataResponse) }
        }

        return self
    }

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
                responseSerializer:
            DefaultHttpDataRequest.responseSerializer(errorSanitizer: errorSanitizer)) { response in
            completionHandler(response)
        }
        return self
    }
}

// MARK: HttpDataRequest - Private

extension DefaultHttpDataRequest {
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

extension DefaultHttpDataRequest: CustomStringConvertible, CustomDebugStringConvertible {
    private var requestIsNullText: String {
        return "No description available: Null"
    }

    var description: String {
        return request?.description ?? requestIsNullText
    }

    var debugDescription: String {
        return request?.debugDescription ?? requestIsNullText
    }

}
