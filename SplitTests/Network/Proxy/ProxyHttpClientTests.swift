import XCTest
@testable import Split

class ProxyHttpClientTests: XCTestCase {
    func testSendRequest_withProxy_returnsDataAndStatusCode() {
        // Given: a proxy config, tunnel establisher, http executor
        let proxyUrl = URL(string: "https://proxy.example.com:8080")!
        let caCertData = Data([0x01, 0x02, 0x03])
        let proxyConfig = try! ProxyConfiguration(proxyURL: proxyUrl, caCertificateData: caCertData)
        let fakeTunnelEstablisher = FakeTunnelEstablisher()
        let fakeHttpExecutor = FakeHttpExecutor()
        let client = ProxyHttpClient(proxyConfig: proxyConfig, tunnelEstablisher: fakeTunnelEstablisher, httpExecutor: fakeHttpExecutor)
        let url = URL(string: "https://origin.example.com/test")!
        let expectation = self.expectation(description: "ProxyHttpClient completes request")
        
        // When: sending a request
        client.sendRequest(to: url) { data, statusCode, error in
            // Then: should return data and 200 status
            XCTAssertNotNil(data)
            XCTAssertEqual(statusCode, 200)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
}

// --- Fakes for integration test ---
class FakeTunnelEstablisher: SimpleTunnelEstablisher {
    override func establishTunnel(to targetHost: String, port: Int, through proxy: ProxyConfiguration, completion: @escaping (URLSessionStreamTask?, Error?) -> Void) {
        completion(FakeStreamTask(), nil)
    }
}
class FakeHttpExecutor: BasicHttpExecutor {
    override func executeRequest(url: URL, through tunnel: URLSessionStreamTask, completion: @escaping (Data?, Int, Error?) -> Void) {
        completion("FAKE_OK".data(using: .utf8), 200, nil)
    }
}
class FakeStreamTask: URLSessionStreamTask {}
