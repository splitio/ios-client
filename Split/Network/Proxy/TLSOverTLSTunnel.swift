import Foundation
import Network
import Security

/// A TLS-over-TLS tunnel implementation using Network.framework
/// Establishes dual TLS connections: proxy TLS → target TLS
@available(iOS 12.0, *)
class TLSOverTLSTunnel: NSObject {
    
    // MARK: - Configuration Types
    
    /// Configuration for proxy server connection
    struct ProxyConfig {
        let host: String
        let port: Int
        let allowsInsecureConnection: Bool
        let caCertificates: [SecCertificate]?
        
        init(host: String, port: Int, allowsInsecureConnection: Bool = false, caCertificates: [SecCertificate]? = nil) {
            self.host = host
            self.port = port
            self.allowsInsecureConnection = allowsInsecureConnection
            self.caCertificates = caCertificates
        }
    }
    
    /// Configuration for target server connection
    struct TargetConfig {
        let host: String
        let port: Int
        let caCertificates: [SecCertificate]?
        let allowsInsecureConnection: Bool
        let alpnProtocols: [String]?
        
        init(host: String, port: Int, caCertificates: [SecCertificate]? = nil, 
             allowsInsecureConnection: Bool = false, alpnProtocols: [String]? = nil) {
            self.host = host
            self.port = port
            self.caCertificates = caCertificates
            self.allowsInsecureConnection = allowsInsecureConnection
            self.alpnProtocols = alpnProtocols
        }
    }
    
    // MARK: - Properties
    
    /// Configuration for proxy server connection
    let proxyConfig: ProxyConfig
    
    /// Configuration for target server connection
    let targetConfig: TargetConfig
    
    /// Current connection state
    private var _isConnected: Bool = false
    
    /// Dispatch queue for tunnel operations
    private let queue = DispatchQueue(label: "com.split.tlstunnel", qos: .userInitiated)
    
    /// Network.framework connection to proxy server
    private var proxyConnection: NWConnection?
    
    /// Network.framework connection to target server (through proxy)
    private var targetConnection: NWConnection?
    
    // MARK: - Event Callbacks
    
    /// Called when tunnel is successfully established
    var onConnected: (() -> Void)?
    
    /// Called when data is received from target server
    var onDataReceived: ((Data) -> Void)?
    
    /// Called when an error occurs
    var onError: ((Error) -> Void)?
    
    /// Called when tunnel is disconnected
    var onDisconnected: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Initializes a new TLS-over-TLS tunnel with the specified configurations
    /// - Parameters:
    ///   - proxyConfig: Configuration for the proxy server connection
    ///   - targetConfig: Configuration for the target server connection
    init(proxyConfig: ProxyConfig, targetConfig: TargetConfig) {
        self.proxyConfig = proxyConfig
        self.targetConfig = targetConfig
        super.init()
    }
    
    // MARK: - Public Interface
    
    /// Returns true if the tunnel is currently connected
    var isConnected: Bool {
        return queue.sync { _isConnected }
    }
    
    /// Returns true if Network.framework is supported (iOS 12+)
    var supportsNetworkFramework: Bool {
        return true // Always true since we're marked @available(iOS 12.0, *)
    }
    
    /// Establishes the TLS-over-TLS tunnel connection
    /// This will perform dual TLS handshakes: first to proxy, then to target
    func connect() {
        queue.async { [weak self] in
            self?.performConnectionAttempt()
        }
    }
    
    /// Sends data through the established tunnel
    /// - Parameter data: Data to send to the target server
    func send(data: Data) {
        guard isConnected else {
            onError?(TunnelError.notConnected)
            return
        }
        
        // Minimal implementation - will be expanded in future iterations
        queue.async { [weak self] in
            // In a real implementation, this would send data through the established tunnel
            self?.onDataReceived?(data) // Echo back for testing
        }
    }
    
    /// Disconnects and cleans up the tunnel connection
    func disconnect() {
        queue.async { [weak self] in
            self?.performDisconnection()
        }
    }
    
    // MARK: - Private Implementation
    
    /// Performs the actual connection attempt
    private func performConnectionAttempt() {
        // For now, simulate connection attempt
        // In a real implementation, this would:
        // 1. Create NWConnection to proxy
        // 2. Establish TLS connection to proxy
        // 3. Send CONNECT request through proxy
        // 4. Establish second TLS connection to target
        
        // Simulate async connection attempt
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            // For testing purposes, we'll trigger an error since we don't have real servers
            let error = TunnelError.connectionSimulation
            self?.onError?(error)
        }
    }
    
    /// Performs the disconnection and cleanup
    private func performDisconnection() {
        _isConnected = false
        
        // Clean up Network.framework connections
        proxyConnection?.cancel()
        targetConnection?.cancel()
        proxyConnection = nil
        targetConnection = nil
        
        // Trigger disconnection callback on main queue
        DispatchQueue.main.async { [weak self] in
            self?.onDisconnected?()
        }
    }
    
    /// Establishes connection to proxy server using Network.framework
    func establishProxyConnection() {
        queue.async { [weak self] in
            self?.performProxyConnectionEstablishment()
        }
    }
    
    /// Performs TLS handshake with target server through established proxy tunnel
    func performTargetTLSHandshake() {
        queue.async { [weak self] in
            self?.performTargetTLSHandshakeImplementation()
        }
    }
    
    // MARK: - Network.framework Connection Management
    
    /// Performs the actual proxy connection establishment using Network.framework
    private func performProxyConnectionEstablishment() {
        let tlsOptions = createProxyTLSOptions()
        let parameters = createConnectionParameters(tlsOptions: tlsOptions)
        let endpoint = createProxyEndpoint()
        
        // Create and configure proxy connection
        proxyConnection = NWConnection(to: endpoint, using: parameters)
        configureProxyConnectionHandlers()
        
        // Start connection
        proxyConnection?.start(queue: queue)
    }
    
    /// Creates TLS options for proxy connection with certificate validation
    private func createProxyTLSOptions() -> NWProtocolTLS.Options {
        let tlsOptions = NWProtocolTLS.Options()
        
        // Configure certificate validation based on proxy configuration
        if let caCerts = proxyConfig.caCertificates {
            configureCertificateValidation(tlsOptions: tlsOptions, caCertificates: caCerts)
        } else if proxyConfig.allowsInsecureConnection {
            configureInsecureConnection(tlsOptions: tlsOptions)
        }
        
        return tlsOptions
    }
    
    /// Configures custom CA certificate validation for proxy connection
    private func configureCertificateValidation(tlsOptions: NWProtocolTLS.Options, caCertificates: [SecCertificate]) {
        sec_protocol_options_set_verify_block(tlsOptions.securityProtocolOptions, { (metadata, trust, callback) in
            let trust = sec_trust_copy_ref(trust).takeRetainedValue()
            
            // Set custom CA certificates
            SecTrustSetAnchorCertificates(trust, caCertificates as CFArray)
            SecTrustSetAnchorCertificatesOnly(trust, true)
            
            // Evaluate trust
            var error: CFError?
            let result = SecTrustEvaluateWithError(trust, &error)
            callback(result)
        }, queue)
    }
    
    /// Configures insecure connection (bypasses certificate validation)
    private func configureInsecureConnection(tlsOptions: NWProtocolTLS.Options) {
        sec_protocol_options_set_verify_block(tlsOptions.securityProtocolOptions, { _, _, callback in
            callback(true)
        }, queue)
    }
    
    /// Creates connection parameters with optimized TCP and TLS settings
    private func createConnectionParameters(tlsOptions: NWProtocolTLS.Options) -> NWParameters {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.noDelay = true // Disable Nagle's algorithm for lower latency
        
        return NWParameters(tls: tlsOptions, tcp: tcpOptions)
    }
    
    /// Creates network endpoint for proxy server
    private func createProxyEndpoint() -> NWEndpoint {
        return NWEndpoint.hostPort(
            host: NWEndpoint.Host(proxyConfig.host),
            port: NWEndpoint.Port(integerLiteral: UInt16(proxyConfig.port))
        )
    }
    
    /// Configures state change handlers for proxy connection
    private func configureProxyConnectionHandlers() {
        proxyConnection?.stateUpdateHandler = { [weak self] state in
            self?.handleProxyConnectionStateChange(state)
        }
    }
    
    /// Handles proxy connection state changes
    private func handleProxyConnectionStateChange(_ state: NWConnection.State) {
        switch state {
        case .ready:
            sendConnectRequest()
        case .failed(let error):
            DispatchQueue.main.async { [weak self] in
                self?.onError?(TunnelError.proxyConnectionFailed(error))
            }
        case .cancelled:
            performDisconnection()
        default:
            break
        }
    }
    
    // MARK: - HTTP CONNECT Protocol Implementation
    
    /// Sends HTTP CONNECT request through proxy connection
    private func sendConnectRequest() {
        guard let connection = proxyConnection else {
            reportError(.noProxyConnection)
            return
        }
        
        let requestData = createConnectRequestData()
        sendConnectRequestData(requestData, through: connection)
    }
    
    /// Creates HTTP CONNECT request data following RFC 7231 specification
    private func createConnectRequestData() -> Data? {
        let connectRequest = buildConnectRequestString()
        
        guard let requestData = connectRequest.data(using: .utf8) else {
            reportError(.invalidConnectRequest)
            return nil
        }
        
        return requestData
    }
    
    /// Builds HTTP CONNECT request string with proper headers
    private func buildConnectRequestString() -> String {
        return "CONNECT \(targetConfig.host):\(targetConfig.port) HTTP/1.1\r\n" +
               "Host: \(targetConfig.host):\(targetConfig.port)\r\n" +
               "Proxy-Connection: Keep-Alive\r\n" +
               "User-Agent: Split-iOS-SDK/TLS-Tunnel\r\n\r\n"
    }
    
    /// Sends CONNECT request data through the proxy connection
    private func sendConnectRequestData(_ requestData: Data?, through connection: NWConnection) {
        guard let requestData = requestData else { return }
        
        connection.send(content: requestData, completion: .contentProcessed { [weak self] error in
            if let error = error {
                self?.reportError(.connectRequestFailed(error))
            } else {
                self?.receiveConnectResponse()
            }
        })
    }
    
    /// Receives and processes HTTP CONNECT response
    private func receiveConnectResponse() {
        guard let connection = proxyConnection else { return }
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, isComplete, error in
            self?.handleConnectResponse(data: data, isComplete: isComplete, error: error)
        }
    }
    
    /// Handles the received HTTP CONNECT response data
    private func handleConnectResponse(data: Data?, isComplete: Bool, error: Error?) {
        // Handle connection errors
        if let error = error {
            reportError(.connectResponseFailed(error))
            return
        }
        
        // Handle unexpected connection closure
        if isComplete {
            reportError(.connectionClosed)
            return
        }
        
        // Process response data
        guard let responseData = data else {
            reportError(.invalidConnectResponse)
            return
        }
        
        processConnectResponseData(responseData)
    }
    
    /// Processes the HTTP CONNECT response data and validates success
    private func processConnectResponseData(_ data: Data) {
        guard let response = String(data: data, encoding: .utf8) else {
            reportError(.invalidConnectResponse)
            return
        }
        
        if isSuccessfulConnectResponse(response) {
            // Tunnel established successfully, proceed to target TLS handshake
            performTargetTLSHandshakeImplementation()
        } else {
            reportError(.connectRequestRejected(response))
        }
    }
    
    /// Validates if the HTTP CONNECT response indicates success (HTTP 200)
    private func isSuccessfulConnectResponse(_ response: String) -> Bool {
        return response.contains("200") && response.contains("HTTP/1.")
    }
    
    /// Reports errors to the main queue via the error callback
    private func reportError(_ error: TunnelError) {
        DispatchQueue.main.async { [weak self] in
            self?.onError?(error)
        }
    }
    
    /// Performs the target TLS handshake implementation
    private func performTargetTLSHandshakeImplementation() {
        // For now, simulate the target TLS handshake
        // In a real implementation, this would establish a second TLS connection
        // through the proxy tunnel to the target server
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            // Simulate handshake attempt
            self?.onError?(TunnelError.targetHandshakeSimulation)
        }
    }
    
    // MARK: - Error Types
    
    /// Errors that can occur during tunnel operations
    enum TunnelError: LocalizedError {
        case connectionSimulation
        case notConnected
        case proxyConnectionFailed(Error)
        case noProxyConnection
        case invalidConnectRequest
        case connectRequestFailed(Error)
        case connectResponseFailed(Error)
        case connectionClosed
        case invalidConnectResponse
        case connectRequestRejected(String)
        case targetHandshakeSimulation
        
        var errorDescription: String? {
            switch self {
            case .connectionSimulation:
                return "Connection simulation - no real server available"
            case .notConnected:
                return "Cannot send data: tunnel not connected"
            case .proxyConnectionFailed(let error):
                return "Proxy connection failed: \(error.localizedDescription)"
            case .noProxyConnection:
                return "No proxy connection available"
            case .invalidConnectRequest:
                return "Failed to create CONNECT request"
            case .connectRequestFailed(let error):
                return "CONNECT request failed: \(error.localizedDescription)"
            case .connectResponseFailed(let error):
                return "CONNECT response failed: \(error.localizedDescription)"
            case .connectionClosed:
                return "Connection closed unexpectedly"
            case .invalidConnectResponse:
                return "Invalid CONNECT response"
            case .connectRequestRejected(let response):
                return "CONNECT request rejected: \(response)"
            case .targetHandshakeSimulation:
                return "Target TLS handshake simulation - not yet implemented"
            }
        }
        
        var errorCode: Int {
            switch self {
            case .connectionSimulation: return -1
            case .notConnected: return -2
            case .proxyConnectionFailed: return -3
            case .noProxyConnection: return -4
            case .invalidConnectRequest: return -5
            case .connectRequestFailed: return -6
            case .connectResponseFailed: return -7
            case .connectionClosed: return -8
            case .invalidConnectResponse: return -9
            case .connectRequestRejected: return -10
            case .targetHandshakeSimulation: return -11
            }
        }
    }
}
