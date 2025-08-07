import Foundation
import Network
import Security

/// Integration point for proxy stack
class ProxyHttpClient {
    private let proxyConfig: ProxyConfiguration?
    private let tunnelEstablisher: SimpleTunnelEstablisher
    private let httpExecutor: BasicHttpExecutor
    
    /// TLS-over-TLS tunnel for Network.framework integration (preferred approach)
    private var tlsTunnel: TLSOverTLSTunnel?
    private var tlsBridge: TLSOverTLSTunnelURLSessionBridge?
    
    /// Indicates whether to use Network.framework TLS tunnel (true) or legacy approach (false)
    private let useNetworkFrameworkTLS: Bool
    
    init(proxyConfig: ProxyConfiguration?,
         tunnelEstablisher: SimpleTunnelEstablisher = SimpleTunnelEstablisher(),
         httpExecutor: BasicHttpExecutor = BasicHttpExecutor(),
         useNetworkFrameworkTLS: Bool = true) {
        self.proxyConfig = proxyConfig
        self.tunnelEstablisher = tunnelEstablisher
        self.httpExecutor = httpExecutor
        self.useNetworkFrameworkTLS = useNetworkFrameworkTLS
        
        // Configure TLS tunnel if using Network.framework approach
        if useNetworkFrameworkTLS {
            self.configureTLSTunnel()
        }
    }
    
    // MARK: - TLS Tunnel Configuration
    
    /// Configures the TLS-over-TLS tunnel for Network.framework integration
    private func configureTLSTunnel() {
        guard let proxyConfig = proxyConfig else { return }
        
        // Extract proxy configuration from URL
        let proxyURL = proxyConfig.proxyURL
        let proxyHost = proxyURL.host ?? "unknown"
        let proxyPort = proxyURL.port ?? 8443
        let caCertificateData = proxyConfig.caCertificateData
        
        print("[ProxyHttpClient] Configuring TLS-over-TLS tunnel with proxy: \(proxyHost):\(proxyPort)")
        
        // Convert certificate data to SecCertificate array
        var caCertificates: [SecCertificate]? = nil
        if let certData = SecCertificateCreateWithData(nil, caCertificateData as CFData) {
            caCertificates = [certData]
        }
        
        // Create proxy configuration for TLS tunnel
        let tunnelProxyConfig = TLSOverTLSTunnel.ProxyConfig(
            host: proxyHost,
            port: proxyPort,
            allowsInsecureConnection: false, // Use secure connections by default
            caCertificates: caCertificates
        )
        
        // Target configuration will be set per request
        // For now, create a placeholder that will be updated per request
        let targetConfig = TLSOverTLSTunnel.TargetConfig(
            host: "placeholder.com",
            port: 443,
            allowsInsecureConnection: false
        )
        
        // Create TLS tunnel and bridge
        self.tlsTunnel = TLSOverTLSTunnel(proxyConfig: tunnelProxyConfig, targetConfig: targetConfig)
        
        if let tunnel = self.tlsTunnel {
            self.tlsBridge = TLSOverTLSTunnelURLSessionBridge(tunnel: tunnel)
            
            // Configure BasicHttpExecutor to use the TLS tunnel
            self.httpExecutor.configureTLSTunnel(self.tlsBridge!) { success in
                if success {
                    print("[ProxyHttpClient] Successfully configured BasicHttpExecutor with Network.framework TLS tunnel")
                } else {
                    print("[ProxyHttpClient] Failed to configure BasicHttpExecutor with TLS tunnel")
                }
            }
        }
    }
    
    /// Sends a GET request to the given URL, using proxy if configured
    func sendRequest(to url: URL, headers: [String: String], completion: @escaping (Data?, Int, Error?) -> Void) {
        guard let proxyConfig = proxyConfig else {
            completion(nil, 0, NSError(domain: "ProxyHttpClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "No proxy configuration provided"]))
            return
        }
        
        // Use Network.framework TLS tunnel approach (preferred - fixes -9806 errors)
        if useNetworkFrameworkTLS, let bridge = tlsBridge {
            print("[ProxyHttpClient] Using Network.framework TLS-over-TLS tunnel for request")
            print("[ProxyHttpClient] Target URL: \(url.absoluteString)")
            
            // Update target configuration for this specific request
            let targetHost = url.host ?? "unknown"
            let targetPort = url.port ?? (url.scheme == "https" ? 443 : 80)
            
            // Create new tunnel with correct target configuration
            let proxyURL = proxyConfig.proxyURL
            let proxyHost = proxyURL.host ?? "unknown"
            let proxyPort = proxyURL.port ?? 8443
            
            // Convert certificate data to SecCertificate array
            var caCertificates: [SecCertificate]? = nil
            if let certData = SecCertificateCreateWithData(nil, proxyConfig.caCertificateData as CFData) {
                caCertificates = [certData]
            }
            
            let tunnelProxyConfig = TLSOverTLSTunnel.ProxyConfig(
                host: proxyHost,
                port: proxyPort,
                allowsInsecureConnection: false,
                caCertificates: caCertificates
            )
            
            let targetConfig = TLSOverTLSTunnel.TargetConfig(
                host: targetHost,
                port: targetPort,
                allowsInsecureConnection: false
            )
            
            let requestTunnel = TLSOverTLSTunnel(proxyConfig: tunnelProxyConfig, targetConfig: targetConfig)
            let requestBridge = TLSOverTLSTunnelURLSessionBridge(tunnel: requestTunnel)
            
            // Execute request through Network.framework TLS tunnel
            requestBridge.executeRequest(url: url, headers: headers) { data, response, error in
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                completion(data, statusCode, error)
            }
            return
        }
        
        // Fallback to legacy approach (may cause -9806 errors with HTTPS)
        print("[ProxyHttpClient] WARNING: Using legacy SimpleTunnelEstablisher + Security framework approach")
        print("[ProxyHttpClient] This may cause -9806 errors with HTTPS requests")
        
        tunnelEstablisher.establishTunnel(to: url.host ?? "", port: url.port ?? 443, through: proxyConfig) { tunnel, error in
            guard let tunnel = tunnel, error == nil else {
                completion(nil, 0, error)
                return
            }
            self.httpExecutor.executeRequest(url: url, headers: headers, through: tunnel, completion: completion)
        }
    }
}
