//
//  HttpRequestList.swift
//  Http
//
//  Created by Javier L. Avrudsky on 08/07/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

// MARK: Request list
public class HttpRequestList: @unchecked Sendable {
    private let queueName = "split.http-request-queue"
    private var queue: DispatchQueue
    private var requests: [Int: HttpRequest]

    public init() {
        queue = DispatchQueue(label: queueName, attributes: .concurrent)
        requests = [Int: HttpRequest]()
    }

    public func set(_ request: HttpRequest) {
        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                self.requests[request.identifier] = request
            }
        }
    }

    public func get(identifier: Int) -> HttpRequest? {
        var request: HttpRequest?
        queue.sync {
            request = requests[identifier]
        }
        return request
    }

    public func take(identifier: Int) -> HttpRequest? {
        var request: HttpRequest?
        queue.sync {
            request = requests[identifier]
            if request != nil {
                queue.async(flags: .barrier) { [weak self] in
                    if let self = self {
                        self.requests.removeValue(forKey: identifier)
                    }
                }
            }
        }
        return request
    }

    public func clear() {
        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                self.requests.removeAll()
            }
        }
    }
}
