import XCTest
import Network
@testable import Split

class TLSOverTLSTunnelURLSessionBridgeTests: XCTestCase {
    
    // MARK: - Phase 4: URLSession Integration Tests
    
    func testTunnelURLSessionBridgeCreation() {
        // Given a configured TLS tunnel
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
        
        // When creating a URLSession bridge
        let bridge = TLSOverTLSTunnelURLSessionBridge(tunnel: tunnel)
        
        // Then the bridge should be created successfully
        XCTAssertNotNil(bridge, "URLSession bridge should be created with valid tunnel")
        XCTAssertTrue(bridge.isReady, "Bridge should be ready for URLSession integration")
    }
    
    func testBridgeURLSessionTaskCreation() {
        // Given a tunnel bridge
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(host: "proxy.test.com", port: 8443)
        let targetConfig = TLSOverTLSTunnel.TargetConfig(host: "api.test.com", port: 443)
        let tunnel = TLSOverTLSTunnel(proxyConfig: proxyConfig, targetConfig: targetConfig)
        let bridge = TLSOverTLSTunnelURLSessionBridge(tunnel: tunnel)
        
        // When creating a URLSession task
        let url = URL(string: "https://api.test.com/endpoint")!
        let task = bridge.createDataTask(for: url)
        
        // Then the task should be created and configured for tunnel usage
        XCTAssertNotNil(task, "URLSession task should be created")
        XCTAssertEqual(task.originalRequest?.url, url, "Task should have correct URL")
    }
    
    func testBridgeHTTPRequestExecution() {
        // Given a tunnel bridge ready for requests
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(host: "proxy.test.com", port: 8443)
        let targetConfig = TLSOverTLSTunnel.TargetConfig(host: "api.test.com", port: 443)
        let tunnel = TLSOverTLSTunnel(proxyConfig: proxyConfig, targetConfig: targetConfig)
        let bridge = TLSOverTLSTunnelURLSessionBridge(tunnel: tunnel)
        
        // When executing an HTTP request
        let expectation = XCTestExpectation(description: "HTTP request should be attempted")
        var requestAttempted = false
        
        let url = URL(string: "https://api.test.com/endpoint")!
        bridge.executeRequest(url: url, headers: ["User-Agent": "Split-iOS-SDK"]) { data, response, error in
            // We expect an error since we don't have real servers
            // But the request attempt should be made
            requestAttempted = true
            expectation.fulfill()
        }
        
        // Then the request should be attempted through the tunnel
        wait(for: [expectation], timeout: 10.0)
        XCTAssertTrue(requestAttempted, "HTTP request should be attempted through tunnel")
    }
    
    func testBridgeBasicHttpExecutorIntegration() {
        // Given a tunnel bridge and BasicHttpExecutor
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(host: "proxy.test.com", port: 8443)
        let targetConfig = TLSOverTLSTunnel.TargetConfig(host: "api.test.com", port: 443)
        let tunnel = TLSOverTLSTunnel(proxyConfig: proxyConfig, targetConfig: targetConfig)
        let bridge = TLSOverTLSTunnelURLSessionBridge(tunnel: tunnel)
        let executor = BasicHttpExecutor()
        
        // When integrating bridge with BasicHttpExecutor
        let streamTask = bridge.createStreamTaskForExecutor()
        
        // Then the stream task should be compatible with BasicHttpExecutor
        XCTAssertNotNil(streamTask, "Stream task should be created for BasicHttpExecutor")
        XCTAssertTrue(bridge.isCompatibleWithBasicHttpExecutor, "Bridge should be compatible with BasicHttpExecutor")
    }
    
    func testBridgeConnectionStateManagement() {
        // Given a tunnel bridge
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(host: "proxy.test.com", port: 8443)
        let targetConfig = TLSOverTLSTunnel.TargetConfig(host: "api.test.com", port: 443)
        let tunnel = TLSOverTLSTunnel(proxyConfig: proxyConfig, targetConfig: targetConfig)
        let bridge = TLSOverTLSTunnelURLSessionBridge(tunnel: tunnel)
        
        // When checking connection state
        let initialState = bridge.connectionState
        
        // Then the bridge should manage connection state properly
        XCTAssertEqual(initialState, .disconnected, "Initial state should be disconnected")
        XCTAssertFalse(bridge.isConnected, "Bridge should not be connected initially")
    }
    
    func testBridgeErrorHandling() {
        // Given a tunnel bridge with invalid configuration
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(host: "", port: 0) // Invalid config
        let targetConfig = TLSOverTLSTunnel.TargetConfig(host: "", port: 0) // Invalid config
        let tunnel = TLSOverTLSTunnel(proxyConfig: proxyConfig, targetConfig: targetConfig)
        let bridge = TLSOverTLSTunnelURLSessionBridge(tunnel: tunnel)
        
        // When attempting to use the bridge
        let expectation = XCTestExpectation(description: "Error should be reported")
        var errorReceived: Error?
        
        bridge.onError = { error in
            errorReceived = error
            expectation.fulfill()
        }
        
        let url = URL(string: "https://invalid.test.com")!
        bridge.executeRequest(url: url, headers: [:]) { _, _, _ in }
        
        // Then appropriate errors should be handled
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(errorReceived, "Error should be reported for invalid configuration")
    }
}
