//
//  HttpRequestList.swift
//  Split
//
//  Created by Javier L. Avrudsky on 08/07/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

// MARK: Request list
class HttpRequestList {
    private let queueName = "split.http-request-queue"
    private var queue: DispatchQueue
    private var requests: [Int: HttpRequest]

    init() {
        queue = DispatchQueue(label: queueName, attributes: .concurrent)
        requests = [Int: HttpRequest]()
    }

    func set(_ request: HttpRequest) {
        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                self.requests[request.identifier] = request
            }
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
                self.requests.removeValue(forKey: identifier)
            }
        }
        return request
    }

    func clear() {
        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                self.requests.removeAll()
            }
        }
    }
}
