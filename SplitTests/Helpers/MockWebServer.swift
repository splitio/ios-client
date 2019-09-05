//
//  MockWebServer.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/07/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
import Swifter

typealias PathRequest = ((Int) -> Void)

struct ReceivedRequest {
    var identifier: String
    var path: String
    var data: String?
    var method: String
}

struct MockedResponse {
    var code: Int
    var data: String?
}

enum MockedMethod: String {
    case get = "GET"
    case post = "POST"
}

class RequestCounter {
    private var counters = [String: Int]()

    func count(for path: String) -> Int {
        var count = 0
        DispatchQueue.global().sync(flags: .barrier) {
            count = self.counters[path] ?? 0
            self.counters[path] = count + 1
        }
        return count
    }

    func reset() {
        DispatchQueue.global().async(flags: .barrier) {
            self.counters.removeAll()
        }
    }
}

class MockWebServer {
    
    let httpServer = HttpServer()
    var receivedRequests = [ReceivedRequest]()
    let requestCounts = RequestCounter()
    
    init() {
    }
    
    func routeGet(path: String, data: String?) {
        return route(method: .get, path: path, responses: [MockedResponse(code: 200, data: data)], onRequest: nil)
    }
    
    func routePost(path: String, data: String?) {
        return route(method: .post, path: path, responses: [MockedResponse(code: 200, data: data)], onRequest: nil)
    }

    func route(method: MockedMethod, path: String, responses: [MockedResponse]?, onRequest: PathRequest?) {

        let respHandler: (Swifter.HttpRequest) -> Swifter.HttpResponse = { [weak self] request in
            var mockedResponse: MockedResponse?
            var responseIndex: Int = 0
            if let self = self {
                responseIndex = self.requestCounts.count(for: request.path)
                self.receivedRequests.append(ReceivedRequest(
                    identifier:  self.buildRequestIdentifier(request: request),
                    path: request.path,
                    data: self.bytesToString(bytes: request.body),
                    method: method.rawValue))
            }

            if let responses = responses, responseIndex < responses.count {
                    mockedResponse = responses[responseIndex]
            }

            if let onRequest = onRequest {
                onRequest(responseIndex)
            }

            if let response = mockedResponse {
                if response.code == 200 {
                    return HttpResponse.ok(.text(response.data ?? ""))
                } else {
                    return HttpResponse.raw(response.code, "", nil, nil)
                }
            }
            return HttpResponse.ok(.text(""))
        }

        switch method {
        case .get:
            httpServer.GET[path] = respHandler
        case .post:
            httpServer.POST[path] = respHandler
        }
    }
    
    private func bytesToString(bytes: [UInt8]?) -> String? {
        guard let bytes = bytes else { return nil }
        return String(bytes: bytes, encoding: .utf8)
    }

    private func buildRequestIdentifier(request: HttpRequest) -> String {
        var params = ""
        for (pname, pvalue) in request.params {
            params += "p[\(pname)|\(pvalue)]"
        }

        var qparams = ""
        for (pname, pvalue) in request.queryParams {
            qparams += "q[\(pname)|\(pvalue)]"
        }

        let identifier = "<method:\(request.method)><path:\(request.path)><params:\(qparams)><qparams:\(params)>"
        print("identifier: \(identifier)")
        return identifier

    }

    func start() {
        httpServer.GET["/test_server"] = { request in
            return HttpResponse.ok(.text("Test server success!!!"))
        }

        try! httpServer.start(8080)
        print("Mock web server started")
    }
    
    func stop() {
        httpServer.stop()
        print("Mock web server stoped")
    }
    
}
