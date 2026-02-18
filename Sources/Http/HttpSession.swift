//  HttpSession
//  Created by Javier L. Avrudsky on 08/07/2020.
//  Copyright © 2020 Split. All rights reserved.

import Foundation

/// Protocol to allow adding Split http classes into the test harness.
public protocol HttpSession: AnyObject {
    func startTask(with request: HttpRequest) -> HttpTask?
    func finalize()
}

class DefaultHttpSession: HttpSession, @unchecked Sendable {

    var urlSession: URLSession

    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }

    func startTask(with request: HttpRequest) -> HttpTask? {

        guard let request = request as? BaseHttpRequest else {
            return nil
        }

        guard let task = createSessionTask(request: request, body: request.body)  else {
            return nil
        }
        task.resume()
        return HttpDataTask(sessionTask: task)

    }

    private func createSessionTask(request: BaseHttpRequest, body: Data?) -> URLSessionTask? {
        guard let urlRequest = request.urlRequest else {
            return nil
        }
        if request.method.isUpload, let body = body {
            return urlSession.uploadTask(with: urlRequest, from: body)
        }
        return urlSession.dataTask(with: urlRequest)
    }

    func finalize() {
        urlSession.invalidateAndCancel()
    }
}
