//
//  HttpTask.swift
//  Split
//
//  Created by Javier L. Avrudsky on 25/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

/// Represents a network task
/// It is intended to wrap URLSessionTask to allow testing easly
protocol HttpTask {
    var identifier: Int { get }
}

class HttpDataTask: HttpTask {

    var identifier: Int {
        return urlSessionTask.taskIdentifier
    }

    private (set) var urlSessionTask: URLSessionTask

    init(urlSessionTask: URLSessionTask) {
        self.urlSessionTask = urlSessionTask
    }

}
