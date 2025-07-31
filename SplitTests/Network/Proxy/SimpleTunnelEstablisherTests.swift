import XCTest
@testable import Split

class SimpleTunnelEstablisherTests: XCTestCase {
    func testEstablishTunnel_successfulConnect_returnsStreamTask() {
        // Given: a valid ProxyConfiguration (dummy CA data for now)
        let proxyUrl = URL(string: "https://proxy.example.com:8080")!
        let caCertData = Data([0x01, 0x02, 0x03])
        let proxyConfig = try! ProxyConfiguration(proxyURL: proxyUrl, caCertificateData: caCertData)
        let establisher = SimpleTunnelEstablisher()
        let expectation = self.expectation(description: "Tunnel establishment completes")
        
        // When: establishing a tunnel (simulate with test double or expectation)
        establisher.establishTunnel(to: "origin.example.com", port: 443, through: proxyConfig) { streamTask, error in
            // Then: the streamTask should not be nil
            XCTAssertNotNil(streamTask)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testEstablishTunnel_connectionFailure_returnsError() {
        // Given: a valid ProxyConfiguration (dummy CA data for now)
        let proxyUrl = URL(string: "https://proxy.example.com:8080")!
        let caCertData = Data([0x01, 0x02, 0x03])
        let proxyConfig = try! ProxyConfiguration(proxyURL: proxyUrl, caCertificateData: caCertData)
        let establisher = SimpleTunnelEstablisher()
        let expectation = self.expectation(description: "Tunnel establishment fails")
        
        // When: simulate a failure (for now, use a flag or test double in the implementation)
        establisher.establishTunnel(to: "fail.example.com", port: 443, through: proxyConfig) { streamTask, error in
            // Then: should return error, not a stream task
            XCTAssertNil(streamTask)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }
}
