//
//  MockWebServer.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/07/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
import Swifter

struct ClientRequest {
    var identifier: String
    var path: String
    var data: String?
    var method: String
}

typealias RequestHandler = ((ClientRequest) -> MockedResponse)

struct MockedResponse {
    var code: Int
    var data: String?
}

enum MockedMethod: String {
    case get = "GET"
    case post = "POST"
}

class MockWebServer {
    
    let httpServer = HttpServer()
    var receivedRequests = [ClientRequest]()
    
    init() {
    }
    
    func routeGet(path: String, data: String? = nil) {
        return route(method: .get, path: path, requestHandler: { request in
                       return MockedResponse(code: 200, data: data)
                   })
    }
    
    func routePost(path: String, data: String? = nil) {
        return route(method: .post, path: path, requestHandler: { request in
                return MockedResponse(code: 200, data: data)
            })
    }

    func route(method: MockedMethod, path: String, requestHandler: RequestHandler?) {

        let respHandler: (Swifter.HttpRequest) -> Swifter.HttpResponse = { [weak self] request in
            var mockedResponse: MockedResponse?
            if let self = self {

                let clientRequest = ClientRequest(
                    identifier:  self.buildRequestIdentifier(request: request),
                    path: request.path,
                    data: self.bytesToString(bytes: request.body),
                    method: request.method)

                self.receivedRequests.append(clientRequest)

                if let requestHandler = requestHandler {
                    mockedResponse = requestHandler(clientRequest)
                }
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
        while(httpServer.state == .starting) {
        }
        print("Mock web server started")
    }
    
    func stop() {
        httpServer.stop()
        while(httpServer.state != .stopped) {
        }
        print("Mock web server stoped")
    }
    
}
