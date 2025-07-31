import Foundation

/// Minimal HTTP executor for requests through a proxy tunnel
class BasicHttpExecutor {
    /// Executes a GET request through the given tunnel
    /// Calls completion with response data, status code, or error
    func executeRequest(url: URL, through tunnel: URLSessionStreamTask, completion: @escaping (Data?, Int, Error?) -> Void) {
        // Compose minimal HTTP GET request
        let path = url.path.isEmpty ? "/" : url.path
        let host = url.host ?? ""
        let request = "GET \(path) HTTP/1.1\r\nHost: \(host)\r\nConnection: close\r\n\r\n"
        guard let requestData = request.data(using: .utf8) else {
            completion(nil, 0, NSError(domain: "BasicHttpExecutor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode HTTP request"]))
            return
        }
        tunnel.write(requestData, timeout: 2) { writeError in
            if let writeError = writeError {
                completion(nil, 0, writeError)
                return
            }
            // Read HTTP response (status line + headers + body)
            tunnel.readData(ofMinLength: 1, maxLength: 4096, timeout: 5) { responseData, _, readError in
                guard let responseData = responseData, readError == nil else {
                    completion(nil, 0, readError ?? NSError(domain: "BasicHttpExecutor", code: -2, userInfo: [NSLocalizedDescriptionKey: "No response or read error"]))
                    return
                }
                // Parse status code and body
                let responseStr = String(data: responseData, encoding: .utf8) ?? ""
                let lines = responseStr.components(separatedBy: "\r\n")
                guard let statusLine = lines.first, statusLine.hasPrefix("HTTP/1.1") || statusLine.hasPrefix("HTTP/1.0") else {
                    completion(nil, 0, NSError(domain: "BasicHttpExecutor", code: -3, userInfo: [NSLocalizedDescriptionKey: "Malformed HTTP response: \(responseStr)"]))
                    return
                }
                let statusCode = Int(statusLine.split(separator: " ").dropFirst().first ?? "0") ?? 0
                // Find start of body
                if let headerEndRange = responseStr.range(of: "\r\n\r\n") {
                    let bodyStart = headerEndRange.upperBound
                    let body = responseStr[bodyStart...]
                    completion(Data(body.utf8), statusCode, nil)
                } else {
                    completion(nil, statusCode, NSError(domain: "BasicHttpExecutor", code: -4, userInfo: [NSLocalizedDescriptionKey: "No body in HTTP response"]))
                }
            }
        }
    }
}
