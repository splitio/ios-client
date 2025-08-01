import XCTest
@testable import Split

class DefaultHttpClientProxyIntegrationTests: XCTestCase {
    func testSendRequest_withProxyClient_routesToProxy_andReturnsData() throws {
        // Given: a DefaultHttpClient with a fake ProxyHttpClient
        let client = DefaultHttpClient()
        let fakeProxyConfig = try! ProxyConfiguration(proxyURL: URL(string: "https://proxy.example.com")!, caCertificateData: Data([0x01]))
        let fakeProxyClient = FakeProxyHttpClient(proxyConfig: fakeProxyConfig)
        client.setProxyClientForTest(fakeProxyClient)
        let endpoint = Endpoint.builder(baseUrl: URL(string: "https://origin.example.com")!, path: "test").build()
        
        // When: sending a GET request
        let dataRequest = try client.sendRequest(endpoint: endpoint, parameters: nil, headers: nil, body: nil)
        _ = dataRequest.getResponse(completionHandler: { (response: HttpResponse) in
            // Then: should return a successful response with 200 code
            XCTAssertTrue(response.result.isSuccess)
            XCTAssertEqual(response.code, 200)
        }, errorHandler: { error in
            XCTFail("Proxy path should not fail: \(error)")
        })
        dataRequest.send()
    }
}

// --- Fakes for test ---
class FakeProxyHttpClient: ProxyHttpClient {
    override func sendRequest(to url: URL, completion: @escaping (Data?, Int, Error?) -> Void) {
        completion("PROXY_OK".data(using: .utf8), 200, nil)
    }
}
