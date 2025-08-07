import XCTest
import Network
@testable import Split

class BasicHttpExecutorTLSIntegrationTest: XCTestCase {
    
    // MARK: - TDD Phase: Red - Failing Tests
    
    func testBasicHttpExecutorWithTLSOverTLSTunnel() {
        // Given a BasicHttpExecutor configured to use TLS-over-TLS tunnel instead of Security framework
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(
            host: "proxy.test.com",
            port: 8443,
            allowsInsecureConnection: true
        )
        
        let targetConfig = TLSOverTLSTunnel.TargetConfig(
            host: "api.test.com", 
            port: 443,
            allowsInsecureConnection: true
        )
        
        let tunnel = TLSOverTLSTunnel(proxyConfig: proxyConfig, targetConfig: targetConfig)
        let bridge = TLSOverTLSTunnelURLSessionBridge(tunnel: tunnel)
        let executor = BasicHttpExecutor()
        
        // When configuring executor to use Network.framework tunnel instead of Security framework
        let expectation = XCTestExpectation(description: "Should use TLS tunnel instead of Security framework")
        var usedNetworkFramework = false
        
        // This test will fail initially because BasicHttpExecutor doesn't have this integration yet
        executor.configureTLSTunnel(bridge) { success in
            usedNetworkFramework = success
            expectation.fulfill()
        }
        
        // Then the executor should use Network.framework tunnel instead of deprecated Security framework
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(usedNetworkFramework, "BasicHttpExecutor should use Network.framework TLS tunnel")
        XCTAssertTrue(executor.usesNetworkFrameworkTLS, "Should indicate Network.framework is being used")
    }
    
    func testBasicHttpExecutorHTTPSRequestWithoutSecurityFramework() {
        // Given a BasicHttpExecutor with TLS tunnel integration
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(host: "proxy.test.com", port: 8443)
        let targetConfig = TLSOverTLSTunnel.TargetConfig(host: "api.test.com", port: 443)
        let tunnel = TLSOverTLSTunnel(proxyConfig: proxyConfig, targetConfig: targetConfig)
        let bridge = TLSOverTLSTunnelURLSessionBridge(tunnel: tunnel)
        let executor = BasicHttpExecutor()
        
        // Configure executor to use tunnel (this will fail until we implement it)
        executor.configureTLSTunnel(bridge) { _ in }
        
        // When executing an HTTPS request
        let expectation = XCTestExpectation(description: "Should execute HTTPS without Security framework")
        let url = URL(string: "https://api.test.com/endpoint")!
        var requestAttempted = false
        
        // This should use Network.framework tunnel instead of SSLHandshake
        executor.executeHTTPSRequestWithTunnel(url: url, headers: [:]) { data, statusCode, error in
            requestAttempted = true
            expectation.fulfill()
        }
        
        // Then the request should be attempted using Network.framework (not Security framework)
        wait(for: [expectation], timeout: 10.0)
        XCTAssertTrue(requestAttempted, "HTTPS request should be attempted via Network.framework tunnel")
    }
    
    func testBasicHttpExecutorAvoidsSecurityFrameworkSSLHandshake() {
        // Given a BasicHttpExecutor with tunnel integration
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(host: "proxy.test.com", port: 8443)
        let targetConfig = TLSOverTLSTunnel.TargetConfig(host: "api.test.com", port: 443)
        let tunnel = TLSOverTLSTunnel(proxyConfig: proxyConfig, targetConfig: targetConfig)
        let bridge = TLSOverTLSTunnelURLSessionBridge(tunnel: tunnel)
        let executor = BasicHttpExecutor()
        
        // When configuring to avoid Security framework
        executor.configureTLSTunnel(bridge) { _ in }
        
        // Then Security framework SSLHandshake should not be used
        XCTAssertFalse(executor.usesSecurityFrameworkSSL, "Should not use deprecated Security framework SSLHandshake")
        XCTAssertTrue(executor.usesNetworkFrameworkTLS, "Should use modern Network.framework TLS")
    }
}
