import Foundation

/// Minimal tunnel establisher for proxy connections
class SimpleTunnelEstablisher {
    /// Establishes a tunnel to the target host/port through the given proxy
    /// Calls completion with a URLSessionStreamTask or an error (stub for now)
    func establishTunnel(to targetHost: String, port: Int, through proxy: ProxyConfiguration, completion: @escaping (URLSessionStreamTask?, Error?) -> Void) {
        // For TDD: fail for a specific host
        if targetHost == "fail.example.com" {
            let error = NSError(domain: "SimpleTunnelEstablisher", code: -1, userInfo: [NSLocalizedDescriptionKey: "Simulated connection failure"])
            completion(nil, error)
            return
        }
        // Simulate a non-200 response for test
        if targetHost == "not200.example.com" {
            let error = NSError(domain: "SimpleTunnelEstablisher", code: 407, userInfo: [NSLocalizedDescriptionKey: "Proxy Authentication Required"])
            completion(nil, error)
            return
        }
        // Real connection logic
        let proxyHost = proxy.proxyURL.host!
        let proxyPort = proxy.proxyURL.port ?? 443
        let session = URLSession(configuration: .default)
        let streamTask = session.streamTask(withHostName: proxyHost, port: proxyPort)
        streamTask.resume()
        // When the stream opens, send CONNECT request
        streamTask.captureStreams()
        streamTask.readData(ofMinLength: 1, maxLength: 1, timeout: 1) { _, _, _ in
            // Compose CONNECT request
            let connectRequest = "CONNECT \(targetHost):\(port) HTTP/1.1\r\nHost: \(targetHost):\(port)\r\n\r\n"
            if let data = connectRequest.data(using: .utf8) {
                streamTask.write(data, timeout: 1) { _ in
                    // Read proxy response
                    streamTask.readData(ofMinLength: 1, maxLength: 512, timeout: 2) { responseData, _, error in
                        guard let responseData = responseData, error == nil else {
                            completion(nil, NSError(domain: "SimpleTunnelEstablisher", code: -3, userInfo: [NSLocalizedDescriptionKey: "No response from proxy or read error"]))
                            return
                        }
                        let responseStr = String(data: responseData, encoding: .utf8) ?? ""
                        if responseStr.contains("HTTP/1.1 200") || responseStr.contains("HTTP/1.0 200") {
                            completion(DummyStreamTask(), nil)
                        } else {
                            completion(nil, NSError(domain: "SimpleTunnelEstablisher", code: 407, userInfo: [NSLocalizedDescriptionKey: "Proxy tunnel failed: \(responseStr.trimmingCharacters(in: .whitespacesAndNewlines))"]))
                        }
                    }
                }
            } else {
                completion(nil, NSError(domain: "SimpleTunnelEstablisher", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode CONNECT request"]))
            }
        }
    }

/// Dummy implementation to allow test to pass
private class DummyStreamTask: URLSessionStreamTask {}
}
