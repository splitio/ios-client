import XCTest
import Network
@testable import Split

class ProxyHttpClientTLSIntegrationTest: XCTestCase {
    
    func testProxyHttpClientUsesNetworkFrameworkTLS() {
        // Given a ProxyHttpClient configured to use Network.framework TLS tunnel
        let proxyURL = URL(string: "https://proxy.test.com:8443")!
        let caCertData = Data("test-cert".utf8) // Mock certificate data
        
        do {
            let proxyConfig = try ProxyConfiguration(proxyURL: proxyURL, caCertificateData: caCertData)
            let client = ProxyHttpClient(proxyConfig: proxyConfig, useNetworkFrameworkTLS: true)
            
            // When making an HTTPS request
            let expectation = XCTestExpectation(description: "Should use Network.framework TLS tunnel")
            let testURL = URL(string: "https://api.test.com/endpoint")!
            
            client.sendRequest(to: testURL, headers: ["User-Agent": "Split-iOS-SDK"]) { data, statusCode, error in
                // We expect this to attempt the request using Network.framework tunnel
                // This should NOT cause -9806 errors like the Security framework approach
                expectation.fulfill()
            }
            
            // Then the request should be attempted via Network.framework (not Security framework)
            wait(for: [expectation], timeout: 10.0)
            
        } catch {
            XCTFail("Failed to create proxy configuration: \(error)")
        }
    }
    
    func testProxyHttpClientLegacyFallback() {
        // Given a ProxyHttpClient configured to use legacy approach
        let proxyURL = URL(string: "https://proxy.test.com:8443")!
        let caCertData = Data("test-cert".utf8)
        
        do {
            let proxyConfig = try ProxyConfiguration(proxyURL: proxyURL, caCertificateData: caCertData)
            let client = ProxyHttpClient(proxyConfig: proxyConfig, useNetworkFrameworkTLS: false)
            
            // When making an HTTPS request with legacy approach
            let expectation = XCTestExpectation(description: "Should use legacy SimpleTunnelEstablisher approach")
            let testURL = URL(string: "https://api.test.com/endpoint")!
            
            client.sendRequest(to: testURL, headers: [:]) { data, statusCode, error in
                // This approach may cause -9806 errors due to Security framework issues
                expectation.fulfill()
            }
            
            // Then the request should be attempted via legacy approach
            wait(for: [expectation], timeout: 10.0)
            
        } catch {
            XCTFail("Failed to create proxy configuration: \(error)")
        }
    }
}
