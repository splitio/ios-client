import Foundation

/// TLS connection wrapper that bridges Security framework with URLSessionStreamTask
class TLSConnection {
    private let tunnel: URLSessionStreamTask
    private let readSemaphore = DispatchSemaphore(value: 0)
    private let writeSemaphore = DispatchSemaphore(value: 0)
    private var readBuffer: Data?
    private var readError: Error?
    private var writeError: Error?
    
    init(tunnel: URLSessionStreamTask) {
        self.tunnel = tunnel
    }
    
    /// SSL read callback implementation
    func read(data: UnsafeMutableRawPointer?, length: UnsafeMutablePointer<Int>) -> OSStatus {
        guard let data = data else {
            print("[TLSConnection] Read called with null data pointer")
            length.pointee = 0
            return errSSLInternal
        }
        
        let requestedLength = length.pointee
        print("[TLSConnection] Read requested: \(requestedLength) bytes, tunnel state: \(tunnel.state.rawValue)")
        
        // Check tunnel state before attempting read
        guard tunnel.state == .running else {
            print("[TLSConnection] Tunnel not running, state: \(tunnel.state.rawValue)")
            length.pointee = 0
            return errSSLClosedGraceful
        }
        
        // Perform read on tunnel
        tunnel.readData(ofMinLength: 1, maxLength: requestedLength, timeout: 10) { [weak self] responseData, _, error in
            if let error = error {
                print("[TLSConnection] Tunnel read error: \(error.localizedDescription)")
            } else if let data = responseData {
                print("[TLSConnection] Tunnel read success: \(data.count) bytes")
            } else {
                print("[TLSConnection] Tunnel read returned no data and no error")
            }
            self?.readBuffer = responseData
            self?.readError = error
            self?.readSemaphore.signal()
        }
        
        // Wait for read completion
        readSemaphore.wait()
        
        if let error = readError {
            print("[TLSConnection] Read error: \(error.localizedDescription)")
            length.pointee = 0
            return errSSLClosedGraceful
        }
        
        guard let buffer = readBuffer else {
            length.pointee = 0
            return errSSLClosedGraceful
        }
        
        let bytesToCopy = min(buffer.count, requestedLength)
        buffer.withUnsafeBytes { bufferPtr in
            data.copyMemory(from: bufferPtr.baseAddress!, byteCount: bytesToCopy)
        }
        
        length.pointee = bytesToCopy
        return errSecSuccess
    }
    
    /// SSL write callback implementation
    func write(data: UnsafeRawPointer?, length: UnsafeMutablePointer<Int>) -> OSStatus {
        guard let data = data else {
            print("[TLSConnection] Write called with null data pointer")
            length.pointee = 0
            return errSSLInternal
        }
        
        let dataLength = length.pointee
        print("[TLSConnection] Write requested: \(dataLength) bytes, tunnel state: \(tunnel.state.rawValue)")
        
        // Check tunnel state before attempting write
        guard tunnel.state == .running else {
            print("[TLSConnection] Tunnel not running for write, state: \(tunnel.state.rawValue)")
            length.pointee = 0
            return errSSLClosedGraceful
        }
        
        let writeData = Data(bytes: data, count: dataLength)
        
        // Perform write on tunnel
        tunnel.write(writeData, timeout: 10) { [weak self] error in
            if let error = error {
                print("[TLSConnection] Tunnel write error: \(error.localizedDescription)")
            } else {
                print("[TLSConnection] Tunnel write success: \(dataLength) bytes")
            }
            self?.writeError = error
            self?.writeSemaphore.signal()
        }
        
        // Wait for write completion
        writeSemaphore.wait()
        
        if let error = writeError {
            print("[TLSConnection] Write error: \(error.localizedDescription)")
            length.pointee = 0
            return errSSLClosedGraceful
        }
        
        return errSecSuccess
    }
}

/// Minimal HTTP executor for requests through a proxy tunnel
class BasicHttpExecutor {
    /// Executes a GET request through the given tunnel
    /// Calls completion with response data, status code, or error
    func executeRequest(url: URL, headers: [String: String], through tunnel: URLSessionStreamTask, completion: @escaping (Data?, Int, Error?) -> Void) {
        // Check if this is an HTTPS request
        if url.scheme?.lowercased() == "https" {
            executeHttpsRequest(url: url, headers: headers, through: tunnel, completion: completion)
        } else {
            executeHttpRequest(url: url, headers: headers, through: tunnel, completion: completion)
        }
    }
    
    /// Executes an HTTPS request through the tunnel with TLS
    private func executeHttpsRequest(url: URL, headers: [String: String], through tunnel: URLSessionStreamTask, completion: @escaping (Data?, Int, Error?) -> Void) {
        print("[BasicHttpExecutor] HTTPS request detected, establishing TLS connection over tunnel")
        
        // Create TLS context for the connection
        guard let hostname = url.host else {
            completion(nil, 0, NSError(domain: "BasicHttpExecutor", code: -101, userInfo: [NSLocalizedDescriptionKey: "Invalid hostname for HTTPS request"]))
            return
        }
        
        // Establish TLS connection over the existing tunnel
        establishTLSConnection(tunnel: tunnel, hostname: hostname) { [weak self] sslContext, tlsError in
            guard let sslContext = sslContext, tlsError == nil else {
                print("[BasicHttpExecutor] TLS handshake failed: \(tlsError?.localizedDescription ?? "unknown error")")
                completion(nil, 0, tlsError ?? NSError(domain: "BasicHttpExecutor", code: -102, userInfo: [NSLocalizedDescriptionKey: "TLS handshake failed"]))
                return
            }
            
            print("[BasicHttpExecutor] TLS handshake successful, sending HTTPS request")
            
            // Now send the HTTP request over the TLS-secured tunnel
            self?.sendHttpsRequest(url: url, headers: headers, sslContext: sslContext, completion: completion)
        }
    }
    
    /// Establishes TLS connection over the existing tunnel
    private func establishTLSConnection(tunnel: URLSessionStreamTask, hostname: String, completion: @escaping (SSLContext?, Error?) -> Void) {
        print("[BasicHttpExecutor] Starting TLS handshake with \(hostname)")
        print("[BasicHttpExecutor] Tunnel state: \(tunnel.state.rawValue)")
        
        // Create SSL context
        guard let context = SSLCreateContext(nil, .clientSide, .streamType) else {
            let error = NSError(domain: "BasicHttpExecutor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create SSL context"])
            completion(nil, error)
            return
        }
        
        // Set hostname for SNI (Server Name Indication)
        let hostnameStatus = SSLSetPeerDomainName(context, hostname, hostname.count)
        guard hostnameStatus == errSecSuccess else {
            let error = NSError(domain: "BasicHttpExecutor", code: Int(hostnameStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to set peer domain name: \(hostnameStatus)"])
            completion(nil, error)
            return
        }
        
        // Check tunnel state
        print("[BasicHttpExecutor] Checking tunnel state: \(tunnel.state.rawValue) (0=suspended, 1=running, 2=canceling, 3=completed)")
        
        // Check for invalid tunnel states that can't be recovered
        if tunnel.state == .canceling || tunnel.state == .completed {
            let error = NSError(domain: "BasicHttpExecutor", code: -101, userInfo: [NSLocalizedDescriptionKey: "Tunnel is in invalid state: \(tunnel.state.rawValue) - cannot establish TLS connection"])
            completion(nil, error)
            return
        }
        
        if tunnel.state == .suspended {
            print("[BasicHttpExecutor] WARNING: Tunnel is suspended - this should not happen with new implementation")
            print("[BasicHttpExecutor] Attempting to resume tunnel as fallback")
            tunnel.resume()
            
            // Wait for resume to take effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("[BasicHttpExecutor] Tunnel state after resume: \(tunnel.state.rawValue)")
                if tunnel.state == .running {
                    self.proceedWithTLSSetup(tunnel: tunnel, hostname: hostname, context: context, completion: completion)
                } else {
                    let error = NSError(domain: "BasicHttpExecutor", code: -102, userInfo: [NSLocalizedDescriptionKey: "Failed to resume tunnel - state: \(tunnel.state.rawValue)"])
                    completion(nil, error)
                }
            }
        } else if tunnel.state == .running {
            // Tunnel is running as expected - proceed with small delay for proxy cleanup
            print("[BasicHttpExecutor] Tunnel is running, proceeding with TLS setup after cleanup delay")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                print("[BasicHttpExecutor] Proceeding with TLS setup, tunnel state: \(tunnel.state.rawValue)")
                self.proceedWithTLSSetup(tunnel: tunnel, hostname: hostname, context: context, completion: completion)
            }
        } else {
            let error = NSError(domain: "BasicHttpExecutor", code: -103, userInfo: [NSLocalizedDescriptionKey: "Tunnel is in unexpected state: \(tunnel.state.rawValue)"])
            completion(nil, error)
        }
    }
    
    /// Proceeds with TLS setup after tunnel is confirmed to be running
    private func proceedWithTLSSetup(tunnel: URLSessionStreamTask, hostname: String, context: SSLContext, completion: @escaping (SSLContext?, Error?) -> Void) {
        print("[BasicHttpExecutor] Proceeding with TLS setup, tunnel state: \(tunnel.state.rawValue)")
        
        // Add a small delay to ensure tunnel is ready after proxy cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("[BasicHttpExecutor] Setting up TLS connection to target server after proxy cleanup delay")
            
            // Set up I/O callbacks to use our tunnel
            let connectionRef = Unmanaged.passRetained(TLSConnection(tunnel: tunnel)).toOpaque()
            
            let readCallback: SSLReadFunc = { connection, data, dataLength in
                let tlsConnection = Unmanaged<TLSConnection>.fromOpaque(connection).takeUnretainedValue()
                return tlsConnection.read(data: data, length: dataLength)
            }
            
            let writeCallback: SSLWriteFunc = { connection, data, dataLength in
                let tlsConnection = Unmanaged<TLSConnection>.fromOpaque(connection).takeUnretainedValue()
                return tlsConnection.write(data: data, length: dataLength)
            }
            
            SSLSetIOFuncs(context, readCallback, writeCallback)
            SSLSetConnection(context, connectionRef)
            
            // Perform TLS handshake
            self.performTLSHandshake(context: context, connectionRef: connectionRef, completion: completion)
        }
    }
    
    /// Performs the actual TLS handshake
    private func performTLSHandshake(context: SSLContext, connectionRef: UnsafeMutableRawPointer, completion: @escaping (SSLContext?, Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var handshakeStatus: OSStatus
            var handshakeAttempts = 0
            let maxAttempts = 100 // Prevent infinite loop
            
            repeat {
                handshakeAttempts += 1
                handshakeStatus = SSLHandshake(context)
                
                print("[BasicHttpExecutor] TLS handshake attempt \(handshakeAttempts), status: \(handshakeStatus)")
                
                if handshakeStatus == errSSLWouldBlock {
                    // Need more data, continue handshake
                    print("[BasicHttpExecutor] TLS handshake would block, continuing...")
                    usleep(10000) // 10ms delay
                    continue
                } else if handshakeStatus == errSSLClosedAbort {
                    
                    print("[BasicHttpExecutor] TLS handshake aborted - connection closed by peer or network issue")
                    break
                } else if handshakeStatus == errSSLClosedGraceful {
                    print("[BasicHttpExecutor] TLS handshake closed gracefully")
                    break
                } else if handshakeStatus != errSecSuccess {
                    print("[BasicHttpExecutor] TLS handshake failed with unexpected status: \(handshakeStatus)")
                    break
                }
                
                if handshakeAttempts >= maxAttempts {
                    print("[BasicHttpExecutor] TLS handshake exceeded maximum attempts (\(maxAttempts))")
                    handshakeStatus = errSSLClosedAbort
                    break
                }
                
            } while handshakeStatus == errSSLWouldBlock
            
            DispatchQueue.main.async {
                if handshakeStatus == errSecSuccess {
                    print("[BasicHttpExecutor] TLS handshake completed successfully")
                    completion(context, nil)
                } else {
                    print("[BasicHttpExecutor] TLS handshake failed with status: \(handshakeStatus)")
                    // Clean up connection reference on failure
                    Unmanaged<TLSConnection>.fromOpaque(connectionRef).release()
                    let error = NSError(domain: "BasicHttpExecutor", code: Int(handshakeStatus), userInfo: [NSLocalizedDescriptionKey: "TLS handshake failed: \(handshakeStatus)"])
                    completion(nil, error)
                }
            }
        }
    }
    
    /// Sends HTTP request over TLS-secured tunnel
    private func sendHttpsRequest(url: URL, headers: [String: String], sslContext: SSLContext, completion: @escaping (Data?, Int, Error?) -> Void) {
        // Get the connection reference from SSL context for cleanup
        var connectionRef: SSLConnectionRef?
        SSLGetConnection(sslContext, &connectionRef)
          
        defer {
            // Clean up SSL context and connection reference when done
            if let connectionRef = connectionRef {
                Unmanaged<TLSConnection>.fromOpaque(connectionRef).release()
            }
        }
        // Compose HTTP request with upstream headers
        let path = url.path.isEmpty ? "/" : url.path
        let fullPath = url.query != nil ? "\(path)?\(url.query!)" : path
        let host = url.host ?? ""
        var request = "GET \(fullPath) HTTP/1.1\r\nHost: \(host)\r\n"
        
        // Add upstream headers
        for (key, value) in headers {
            request += "\(key): \(value)\r\n"
        }
        
        request += "Connection: close\r\n\r\n"
        
        guard let requestData = request.data(using: .utf8) else {
            completion(nil, 0, NSError(domain: "BasicHttpExecutor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode HTTPS request"]))
            return
        }
        
        print("[BasicHttpExecutor] Sending HTTPS request:")
        print("[BasicHttpExecutor] URL: \(url.absoluteString)")
        print("[BasicHttpExecutor] Path: \(path)")
        print("[BasicHttpExecutor] Full path with query: \(fullPath)")
        print("[BasicHttpExecutor] Query: \(url.query ?? "none")")
        print("[BasicHttpExecutor] Host: \(host)")
        print("[BasicHttpExecutor] Headers count: \(headers.count)")
        
        // Log each header individually
        for (key, value) in headers {
            print("[BasicHttpExecutor] Header: \(key) = \(value)")
        }
        
        // Generate curl command for replication
        var curlCommand = "curl -X GET"
        curlCommand += " '\(url.absoluteString)'"
        for (key, value) in headers {
            curlCommand += " -H '\(key): \(value)'"
        }
        curlCommand += " -H 'Connection: close'"
        curlCommand += " -v"
        print("[BasicHttpExecutor] Curl to replicate: \(curlCommand)")
        
        print("[BasicHttpExecutor] Raw request: \(request.debugDescription)")
        print("[BasicHttpExecutor] Request as string: '\(request)'")
        
        // Write the HTTP request through SSL context (encrypted)
        var bytesWritten: Int = 0
        let writeStatus = SSLWrite(sslContext, requestData.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress }, requestData.count, &bytesWritten)
        
        guard writeStatus == errSecSuccess else {
            print("[BasicHttpExecutor] SSL write error: \(writeStatus)")
            completion(nil, 0, NSError(domain: "BasicHttpExecutor", code: Int(writeStatus), userInfo: [NSLocalizedDescriptionKey: "SSL write failed: \(writeStatus)"]))
            return
        }
        
        print("[BasicHttpExecutor] SSL write successful, wrote \(bytesWritten) bytes")
        
        // Read HTTPS response through SSL context (decrypted)
        let responseBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
        defer { responseBuffer.deallocate() }
        
        var bytesRead: Int = 0
        let readStatus = SSLRead(sslContext, responseBuffer, 4096, &bytesRead)
        
        guard readStatus == errSecSuccess || readStatus == errSSLClosedGraceful else {
            print("[BasicHttpExecutor] SSL read error: \(readStatus)")
            completion(nil, 0, NSError(domain: "BasicHttpExecutor", code: Int(readStatus), userInfo: [NSLocalizedDescriptionKey: "SSL read failed: \(readStatus)"]))
            return
        }
        
        let responseData = Data(bytes: responseBuffer, count: bytesRead)
        
        // Parse HTTPS response (same as HTTP parsing)
        let responseStr = String(data: responseData, encoding: .utf8) ?? ""
        print("[BasicHttpExecutor] Received \(responseData.count) bytes")
        print("[BasicHttpExecutor] HTTPS response: '\(responseStr)'")
        
        let lines = responseStr.components(separatedBy: "\r\n")
        guard let statusLine = lines.first, statusLine.hasPrefix("HTTP/1.1") || statusLine.hasPrefix("HTTP/1.0") else {
            completion(nil, 0, NSError(domain: "BasicHttpExecutor", code: -3, userInfo: [NSLocalizedDescriptionKey: "Malformed HTTPS response: \(responseStr)"]))
            return
        }
        
        let statusCode = Int(statusLine.split(separator: " ").dropFirst().first ?? "0") ?? 0
        
        // Find start of body
        if let headerEndRange = responseStr.range(of: "\r\n\r\n") {
            let bodyStart = headerEndRange.upperBound
            let body = responseStr[bodyStart...]
            completion(Data(body.utf8), statusCode, nil)
        } else {
            completion(nil, statusCode, NSError(domain: "BasicHttpExecutor", code: -4, userInfo: [NSLocalizedDescriptionKey: "No body in HTTPS response"]))
        }
    }
    
    /// Executes a plain HTTP request through the tunnel
    private func executeHttpRequest(url: URL, headers: [String: String], through tunnel: URLSessionStreamTask, completion: @escaping (Data?, Int, Error?) -> Void) {
        // Compose minimal HTTP GET request
        let path = url.path.isEmpty ? "/" : url.path
        let fullPath = url.query != nil ? "\(path)?\(url.query!)" : path
        let host = url.host ?? ""
        var request = "GET \(fullPath) HTTP/1.1\r\nHost: \(host)\r\n"
        
        for (key, value) in headers {
            request += "\(key): \(value)\r\n"
        }
        
        request += "Connection: close\r\n\r\n"
        guard let requestData = request.data(using: .utf8) else {
            completion(nil, 0, NSError(domain: "BasicHttpExecutor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode HTTP request"]))
            return
        }
        
        print("[BasicHttpExecutor] Sending HTTP request:")
        print("[BasicHttpExecutor] URL: \(url.absoluteString)")
        print("[BasicHttpExecutor] Path: \(path)")
        print("[BasicHttpExecutor] Full path with query: \(fullPath)")
        print("[BasicHttpExecutor] Query: \(url.query ?? "none")")
        print("[BasicHttpExecutor] Host: \(host)")
        print("[BasicHttpExecutor] Headers count: \(headers.count)")
        
        // Log each header individually
        for (key, value) in headers {
            print("[BasicHttpExecutor] Header: \(key) = \(value)")
        }
        
        // Generate curl command for replication
        var curlCommand = "curl -X GET"
        curlCommand += " '\(url.absoluteString)'"
        for (key, value) in headers {
            curlCommand += " -H '\(key): \(value)'"
        }
        curlCommand += " -H 'Connection: close'"
        curlCommand += " -v"
        print("[BasicHttpExecutor] Curl to replicate: \(curlCommand)")
        
        print("[BasicHttpExecutor] Raw request: \(request.debugDescription)")
        print("[BasicHttpExecutor] Request as string: '\(request)'")
        
        tunnel.write(requestData, timeout: 2) { writeError in
            if let writeError = writeError {
                completion(nil, 0, writeError)
                return
            }
            // Read HTTP response (status line + headers + body)
            tunnel.readData(ofMinLength: 1, maxLength: 4096, timeout: 5) { responseData, _, readError in
                guard let responseData = responseData, readError == nil else {
                    print("[BasicHttpExecutor] Read error: \(readError?.localizedDescription ?? "unknown")")
                    completion(nil, 0, readError ?? NSError(domain: "BasicHttpExecutor", code: -2, userInfo: [NSLocalizedDescriptionKey: "No response or read error"]))
                    return
                }
                // Parse status code and body
                let responseStr = String(data: responseData, encoding: .utf8) ?? ""
                print("[BasicHttpExecutor] Received \(responseData.count) bytes")
                print("[BasicHttpExecutor] Raw response data: \(responseData.map { String(format: "%02x", $0) }.joined(separator: " "))")
                print("[BasicHttpExecutor] Response as string: '\(responseStr)'")
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
