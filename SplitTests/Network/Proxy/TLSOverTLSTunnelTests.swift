import XCTest
import Network
@testable import Split

class TLSOverTLSTunnelTests: XCTestCase {
    
    // MARK: - Phase 1: Basic Tunnel Creation Tests
    
    func testTunnelCreationWithValidConfiguration() {
        // Given valid proxy and target configurations
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(
            host: "proxy.example.com",
            port: 8443,
            allowsInsecureConnection: false,
            caCertificates: nil
        )
        
        let targetConfig = TLSOverTLSTunnel.TargetConfig(
            host: "api.example.com", 
            port: 443,
            caCertificates: nil,
            allowsInsecureConnection: false,
            alpnProtocols: ["h2", "http/1.1"]
        )
        
        // When creating a TLS tunnel
        let tunnel = TLSOverTLSTunnel(proxyConfig: proxyConfig, targetConfig: targetConfig)
        
        // Then the tunnel should be created successfully
        XCTAssertNotNil(tunnel, "TLS tunnel should be created with valid configuration")
    }
    
    func testProxyConfigurationCreation() {
        // Given valid proxy parameters
        let host = "proxy.test.com"
        let port = 8443
        
        // When creating a proxy configuration
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(
            host: host,
            port: port,
            allowsInsecureConnection: false,
            caCertificates: nil
        )
        
        // Then the configuration should have the correct values
        XCTAssertEqual(proxyConfig.host, host)
        XCTAssertEqual(proxyConfig.port, port)
        XCTAssertNil(proxyConfig.caCertificates)
        XCTAssertFalse(proxyConfig.allowsInsecureConnection)
    }
    
    func testTargetConfigurationCreation() {
        // Given valid target parameters
        let host = "api.test.com"
        let port = 443
        let alpnProtocols = ["h2", "http/1.1"]
        
        // When creating a target configuration
        let targetConfig = TLSOverTLSTunnel.TargetConfig(
            host: host,
            port: port,
            caCertificates: nil,
            allowsInsecureConnection: false,
            alpnProtocols: alpnProtocols
        )
        
        // Then the configuration should have the correct values
        XCTAssertEqual(targetConfig.host, host)
        XCTAssertEqual(targetConfig.port, port)
        XCTAssertNil(targetConfig.caCertificates)
        XCTAssertFalse(targetConfig.allowsInsecureConnection)
        XCTAssertEqual(targetConfig.alpnProtocols, alpnProtocols)
    }
    
    func testTunnelCallbacksInitialization() {
        // Given a tunnel configuration
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(
            host: "proxy.example.com",
            port: 8443
        )
        
        let targetConfig = TLSOverTLSTunnel.TargetConfig(
            host: "api.example.com",
            port: 443
        )
        
        // When creating a tunnel
        let tunnel = TLSOverTLSTunnel(proxyConfig: proxyConfig, targetConfig: targetConfig)
        
        // Then callback properties should be accessible
        tunnel.onConnected = {
            // Connection callback
        }
        
        tunnel.onDataReceived = { data in
            // Data received callback
        }
        
        tunnel.onError = { error in
            // Error callback
        }
        
        tunnel.onDisconnected = {
            // Disconnection callback
        }
        
        // Test passes if no compilation errors occur
        XCTAssertNotNil(tunnel)
    }
    
    // MARK: - Phase 2: Connection Establishment Tests
    
    func testTunnelConnectionEstablishment() {
        // Given a tunnel with valid configuration
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(
            host: "proxy.test.com",
            port: 8443,
            allowsInsecureConnection: true // For testing
        )
        
        let targetConfig = TLSOverTLSTunnel.TargetConfig(
            host: "api.test.com",
            port: 443,
            allowsInsecureConnection: true // For testing
        )
        
        let tunnel = TLSOverTLSTunnel(proxyConfig: proxyConfig, targetConfig: targetConfig)
        
        // When attempting to connect
        let expectation = XCTestExpectation(description: "Connection callback should be called")
        var connectionResult: Bool = false
        var errorResult: Error?
        
        tunnel.onConnected = {
            connectionResult = true
            expectation.fulfill()
        }
        
        tunnel.onError = { error in
            errorResult = error
            expectation.fulfill()
        }
        
        tunnel.connect()
        
        // Then connection should be attempted (will fail in this test, but method should exist)
        wait(for: [expectation], timeout: 5.0)
        
        // For now, we expect an error since we don't have real servers
        // The important thing is that the connection attempt was made
        XCTAssertTrue(connectionResult || errorResult != nil, "Connection attempt should trigger a callback")
    }
    
    func testTunnelConnectionState() {
        // Given a tunnel
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(host: "proxy.test.com", port: 8443)
        let targetConfig = TLSOverTLSTunnel.TargetConfig(host: "api.test.com", port: 443)
        let tunnel = TLSOverTLSTunnel(proxyConfig: proxyConfig, targetConfig: targetConfig)
        
        // When checking initial state
        // Then tunnel should have a way to check if it's connected
        XCTAssertFalse(tunnel.isConnected, "Tunnel should not be connected initially")
    }
    
    func testTunnelDisconnection() {
        // Given a tunnel
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(host: "proxy.test.com", port: 8443)
        let targetConfig = TLSOverTLSTunnel.TargetConfig(host: "api.test.com", port: 443)
        let tunnel = TLSOverTLSTunnel(proxyConfig: proxyConfig, targetConfig: targetConfig)
        
        // When disconnecting
        let expectation = XCTestExpectation(description: "Disconnection callback should be called")
        
        tunnel.onDisconnected = {
            expectation.fulfill()
        }
        
        tunnel.disconnect()
        
        // Then disconnection callback should be triggered
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Phase 3: Network.framework TLS Connection Tests
    
    func testTunnelWithNetworkFrameworkConnection() {
        // Given a tunnel configured for Network.framework
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
        
        // When checking if Network.framework is available
        // Then tunnel should support Network.framework connections
        XCTAssertTrue(tunnel.supportsNetworkFramework, "Tunnel should support Network.framework on iOS 12+")
    }
    
    func testTunnelProxyConnectionEstablishment() {
        // Given a tunnel with proxy configuration
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(
            host: "proxy.test.com",
            port: 8443
        )
        
        let targetConfig = TLSOverTLSTunnel.TargetConfig(
            host: "api.test.com",
            port: 443
        )
        
        let tunnel = TLSOverTLSTunnel(proxyConfig: proxyConfig, targetConfig: targetConfig)
        
        // When establishing proxy connection
        let expectation = XCTestExpectation(description: "Proxy connection should be attempted")
        var connectionAttempted = false
        
        tunnel.onError = { error in
            // We expect an error since we don't have real servers
            // But the connection attempt should be made
            connectionAttempted = true
            expectation.fulfill()
        }
        
        tunnel.establishProxyConnection()
        
        // Then proxy connection should be attempted
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(connectionAttempted, "Proxy connection should be attempted")
    }
    
    func testTunnelTargetTLSHandshake() {
        // Given a tunnel with established proxy connection (simulated)
        let proxyConfig = TLSOverTLSTunnel.ProxyConfig(host: "proxy.test.com", port: 8443)
        let targetConfig = TLSOverTLSTunnel.TargetConfig(host: "api.test.com", port: 443)
        let tunnel = TLSOverTLSTunnel(proxyConfig: proxyConfig, targetConfig: targetConfig)
        
        // When performing target TLS handshake
        let expectation = XCTestExpectation(description: "Target TLS handshake should be attempted")
        var handshakeAttempted = false
        
        tunnel.onError = { error in
            handshakeAttempted = true
            expectation.fulfill()
        }
        
        tunnel.performTargetTLSHandshake()
        
        // Then target TLS handshake should be attempted
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(handshakeAttempted, "Target TLS handshake should be attempted")
    }
}
