import Foundation

/// Error types related to proxy configuration
enum ProxyConfigurationError: Error, Equatable {
    case invalidProxyURL
    case invalidCertificateData
}

/// A configuration for proxy connections with TLS support
public struct ProxyConfiguration {
    /// The URL of the proxy server
    let proxyURL: URL
    
    /// The CA certificate data used to validate the proxy server's certificate
    let caCertificateData: Data
    
    /**
     Initializes a new proxy configuration with the specified URL and CA certificate data
     
     - Parameters:
        - proxyURL: The URL of the proxy server
        - caCertificateData: The CA certificate data used to validate the proxy server's certificate
     
     - Throws: `ProxyConfigurationError.invalidProxyURL` if the URL is invalid
               `ProxyConfigurationError.invalidCertificateData` if the certificate data is empty
     */
    public init(proxyURL: URL, caCertificateData: Data) throws {
        // Validate proxy URL
        guard let scheme = proxyURL.scheme, let host = proxyURL.host, !host.isEmpty else {
            throw ProxyConfigurationError.invalidProxyURL
        }
        
        // Validate certificate data
        guard !caCertificateData.isEmpty else {
            throw ProxyConfigurationError.invalidCertificateData
        }
        
        self.proxyURL = proxyURL
        self.caCertificateData = caCertificateData
    }
}
