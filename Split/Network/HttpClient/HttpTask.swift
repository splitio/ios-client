//
//  HttpTask.swift
//  Split
//
//  Created by Javier L. Avrudsky on 25/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

/// Represents a network task
/// It is intended to wrap URLSessionTask to allow testing easily
protocol HttpTask {
    var identifier: Int { get }
    func cancel()
}

class HttpDataTask: HttpTask {

    var identifier: Int {
        return urlSessionTask.taskIdentifier
    }

    private let urlSessionTask: URLSessionTask

    init(sessionTask: URLSessionTask) {
        self.urlSessionTask = sessionTask
    }

    func cancel() {
        urlSessionTask.cancel()
    }

}
