import Foundation

/// Integration point for proxy stack
class ProxyHttpClient {
    private let proxyConfig: ProxyConfiguration?
    private let tunnelEstablisher: SimpleTunnelEstablisher
    private let httpExecutor: BasicHttpExecutor
    
    init(proxyConfig: ProxyConfiguration?,
         tunnelEstablisher: SimpleTunnelEstablisher = SimpleTunnelEstablisher(),
         httpExecutor: BasicHttpExecutor = BasicHttpExecutor()) {
        self.proxyConfig = proxyConfig
        self.tunnelEstablisher = tunnelEstablisher
        self.httpExecutor = httpExecutor
    }
    
    /// Sends a GET request to the given URL, using proxy if configured
    func sendRequest(to url: URL, completion: @escaping (Data?, Int, Error?) -> Void) {
        guard let proxyConfig = proxyConfig else {
            return
        }
        tunnelEstablisher.establishTunnel(to: url.host ?? "", port: url.port ?? 443, through: proxyConfig) { tunnel, error in
            guard let tunnel = tunnel, error == nil else {
                completion(nil, 0, error)
                return
            }
            self.httpExecutor.executeRequest(url: url, through: tunnel, completion: completion)
        }
    }
}
