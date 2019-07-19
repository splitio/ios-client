//
//  MockWebServer.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/07/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
import Swifter


struct ReceivedRequest {
    var path: String
    var data: String?
    var method: String
}

class MockWebServer {
    
    var httpServer: HttpServer
    var receivedRequests: [ReceivedRequest]
    
    init() {
        httpServer = HttpServer()
        receivedRequests = [ReceivedRequest]()
    }
    
    func routeGet(path: String, data: String?) {
        httpServer.GET[path] = { [weak self] request in
            if let self = self {
                self.receivedRequests.append(ReceivedRequest(path: request.path, data: self.bytesToString(bytes: request.body), method: "GET"))
            }
            return HttpResponse.ok(.text(data ?? ""))
        }
    }
    
    func routePost(path: String, data: String?) {
        httpServer.POST[path] = { request in
            HttpResponse.ok(.text(data ?? ""))
        }
    }
    
    private func bytesToString(bytes: [UInt8]?) -> String? {
        guard let bytes = bytes else { return nil }
        return String(bytes: bytes, encoding: .utf8)
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
