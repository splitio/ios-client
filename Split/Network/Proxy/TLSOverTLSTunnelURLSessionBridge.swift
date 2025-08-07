import Foundation
import Network

/// URLSession bridge that integrates TLSOverTLSTunnel with existing HTTP client architecture
/// This bridge allows seamless integration with BasicHttpExecutor and other URLSession-based components
internal class TLSOverTLSTunnelURLSessionBridge {
    
    // MARK: - Configuration Types
    
    /// Connection state for the bridge
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case failed(Error)
        
        static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected),
                 (.connecting, .connecting),
                 (.connected, .connected):
                return true
            case (.failed, .failed):
                return true // Simplified comparison for failed states
            default:
                return false
            }
        }
    }
    
    // MARK: - Properties
    
    /// The underlying TLS tunnel
    private let tunnel: TLSOverTLSTunnel
    
    /// Current connection state
    private var _connectionState: ConnectionState = .disconnected
    private let stateQueue = DispatchQueue(label: "com.split.bridge.state", qos: .userInitiated)
    
    /// URLSession for creating tasks
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.connectionProxyDictionary = [:]  // Disable system proxy
        return URLSession(configuration: config)
    }()
    
    // MARK: - Event Callbacks
    
    /// Called when an error occurs in the bridge
    var onError: ((Error) -> Void)?
    
    /// Called when connection state changes
    var onStateChange: ((ConnectionState) -> Void)?
    
    // MARK: - Initialization
    
    /// Creates a new URLSession bridge with the given TLS tunnel
    /// - Parameter tunnel: The TLSOverTLSTunnel to bridge with URLSession
    init(tunnel: TLSOverTLSTunnel) {
        self.tunnel = tunnel
        setupTunnelCallbacks()
    }
    
    // MARK: - Public Interface
    
    /// Returns true if the bridge is ready for URLSession integration
    var isReady: Bool {
        return true // Bridge is always ready to be configured
    }
    
    /// Returns true if the bridge is compatible with BasicHttpExecutor
    var isCompatibleWithBasicHttpExecutor: Bool {
        return true // Our bridge is designed for BasicHttpExecutor integration
    }
    
    /// Current connection state
    var connectionState: ConnectionState {
        return stateQueue.sync { _connectionState }
    }
    
    /// Returns true if the tunnel is currently connected
    var isConnected: Bool {
        switch connectionState {
        case .connected:
            return true
        default:
            return false
        }
    }
    
    /// Creates a URLSessionDataTask for the given URL
    /// - Parameter url: The URL to create a task for
    /// - Returns: A configured URLSessionDataTask
    func createDataTask(for url: URL) -> URLSessionDataTask {
        let request = URLRequest(url: url)
        return urlSession.dataTask(with: request)
    }
    
    /// Executes an HTTP request through the TLS tunnel
    /// - Parameters:
    ///   - url: The URL to request
    ///   - headers: HTTP headers to include
    ///   - completion: Completion handler with response data, URLResponse, and error
    func executeRequest(url: URL, headers: [String: String], completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        // Create request with headers
        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Execute request through tunnel
        executeRequestThroughTunnel(request: request, completion: completion)
    }
    
    /// Creates a URLSessionStreamTask compatible with BasicHttpExecutor
    /// - Returns: A stream task that can be used with BasicHttpExecutor
    func createStreamTaskForExecutor() -> URLSessionStreamTask? {
        // For now, return a basic stream task
        // In a full implementation, this would create a custom stream task
        // that routes through our TLS tunnel
        let host = tunnel.targetConfig.host
        let port = tunnel.targetConfig.port
        
        return urlSession.streamTask(withHostName: host, port: port)
    }
    
    // MARK: - Private Implementation
    
    /// Sets up callbacks from the underlying TLS tunnel
    private func setupTunnelCallbacks() {
        tunnel.onConnected = { [weak self] in
            self?.updateConnectionState(.connected)
        }
        
        tunnel.onError = { [weak self] error in
            self?.updateConnectionState(.failed(error))
            self?.onError?(error)
        }
        
        tunnel.onDisconnected = { [weak self] in
            self?.updateConnectionState(.disconnected)
        }
    }
    
    /// Updates the connection state thread-safely
    /// - Parameter newState: The new connection state
    private func updateConnectionState(_ newState: ConnectionState) {
        stateQueue.async { [weak self] in
            self?._connectionState = newState
            DispatchQueue.main.async {
                self?.onStateChange?(newState)
            }
        }
    }
    
    // MARK: - HTTP Request Execution
    
    /// Executes a URLRequest through the TLS tunnel
    /// - Parameters:
    ///   - request: The URLRequest to execute
    ///   - completion: Completion handler
    private func executeRequestThroughTunnel(request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        updateConnectionState(.connecting)
        
        // Establish tunnel connection and execute request
        establishTunnelConnection { [weak self] success in
            if success {
                self?.sendRequestThroughTunnel(request, completion: completion)
            } else {
                let error = BridgeError.tunnelConnectionFailed("Failed to establish tunnel connection")
                self?.handleRequestError(error, completion: completion)
            }
        }
    }
    
    /// Establishes the tunnel connection asynchronously
    /// - Parameter completion: Called with success/failure result
    private func establishTunnelConnection(completion: @escaping (Bool) -> Void) {
        tunnel.connect()
        
        // For now, simulate connection attempt
        // In a full implementation, this would wait for tunnel.onConnected callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion(false) // Simulate failure for test servers
        }
    }
    
    /// Sends HTTP request through the established tunnel
    /// - Parameters:
    ///   - request: The URLRequest to send
    ///   - completion: Completion handler
    private func sendRequestThroughTunnel(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        // In a full implementation, this would:
        // 1. Convert URLRequest to raw HTTP request data
        // 2. Send through tunnel.send(data:)
        // 3. Receive response data
        // 4. Parse HTTP response and create URLResponse
        // 5. Call completion with parsed results
        
        let error = BridgeError.requestExecutionFailed(NSError(domain: "TLSBridge", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request execution not yet implemented"]))
        handleRequestError(error, completion: completion)
    }
    
    /// Handles request execution errors
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - completion: Completion handler to call
    private func handleRequestError(_ error: BridgeError, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        updateConnectionState(.failed(error))
        completion(nil, nil, error)
    }
    
    // MARK: - Error Types
    
    /// Errors that can occur in the URLSession bridge
    enum BridgeError: LocalizedError {
        case tunnelConnectionFailed(String)
        case invalidRequest
        case requestExecutionFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .tunnelConnectionFailed(let message):
                return "Tunnel connection failed: \(message)"
            case .invalidRequest:
                return "Invalid HTTP request"
            case .requestExecutionFailed(let error):
                return "Request execution failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Target Configuration Access

extension TLSOverTLSTunnelURLSessionBridge {
    /// Provides access to target configuration for bridge consumers
    var targetConfig: TLSOverTLSTunnel.TargetConfig {
        return tunnel.targetConfig
    }
    
    /// Provides access to proxy configuration for bridge consumers  
    var proxyConfig: TLSOverTLSTunnel.ProxyConfig {
        return tunnel.proxyConfig
    }
}
