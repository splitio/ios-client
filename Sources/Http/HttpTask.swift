//
//  HttpTask.swift
//  Http
//

import Foundation

/// Represents a network task (wraps URLSessionTask for testability).
public protocol HttpTask: Sendable {
    var identifier: Int { get }
    func cancel()
}

public class HttpDataTask: HttpTask {
    public var identifier: Int {
        urlSessionTask.taskIdentifier
    }

    private let urlSessionTask: URLSessionTask

    public init(sessionTask: URLSessionTask) {
        self.urlSessionTask = sessionTask
    }

    public func cancel() {
        urlSessionTask.cancel()
    }
}
