//
// HttpStreamRequest.swift
// Split
//
// Created by Javier L. Avrudsky on 04/06/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation
protocol HttpStreamRequest {
    var data: Data? { get }
    func appendData(_ newData: Data)
    func getResponse(errorSanitizer: @escaping (JSON, Int) -> HttpResult<JSON>,
                     completionHandler: @escaping (HttpDataResponse<JSON>) -> Void) -> Self
}

// MARK: HttpStreamRequest
class DefaultHttpStreamRequest: BaseHttpRequest, HttpStreamRequest {

    var data: Data?
    var body: Data?

    init(session: HttpSession,
         url: URL,
         headers: HttpHeaders?) {

        super.init(session: session, url: url, method: .get, parameters: nil, headers: headers)
        self.session = session
        self.url = url
        if let headers = headers {
            self.headers = headers
        }
    }

    override func send() {




        task = session.dataTask(with: request)

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
            let dataResponse = HttpDataResponse<JSON>(data: strongSelf.data, result: result)
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
            DefaultHttpStreamRequest.responseSerializer(errorSanitizer: errorSanitizer)) { response in
            completionHandler(response)
        }
        return self
    }
}

// MARK: HttpStreamRequest - Private
extension DefaultHttpStreamRequest {
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

extension DefaultHttpStreamRequest: CustomStringConvertible, CustomDebugStringConvertible {
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
