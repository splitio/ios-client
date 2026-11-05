//  HttpTask
//  Created by Javier L. Avrudsky on 25/06/2020.
//  Copyright © 2020 Split. All rights reserved.

import Foundation

/// Represents a network task. Wraps URLSessionTask to allow testing easily.
public protocol HttpTask {
    var identifier: Int { get }
    func cancel()
}

class HttpDataTask: HttpTask {

    var identifier: Int {
        urlSessionTask.taskIdentifier
    }

    private let urlSessionTask: URLSessionTask

    init(sessionTask: URLSessionTask) {
        self.urlSessionTask = sessionTask
    }

    func cancel() {
        urlSessionTask.cancel()
    }

}
