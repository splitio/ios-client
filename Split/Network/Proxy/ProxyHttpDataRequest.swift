import Foundation

/// Adapter to bridge ProxyHttpClient result to HttpDataRequest contract
class ProxyHttpDataRequest: HttpDataRequest {
    // MARK: HttpRequest required properties
    let url: URL
    let method: HttpMethod = .get
    let parameters: HttpParameters? = nil
    let headers: HttpHeaders = [:]
    let body: Data? = nil
    var responseCode: Int = 0
    var pinnedCredentialFail: Bool = false
    var identifier: Int { return -1 }
    
    // MARK: HttpDataRequest required
    private(set) var data: Data?
    var completion: ((HttpResponse) -> Void)?
    private(set) var sent = false
    private var error: HttpError?
    private var completionHandler: RequestCompletionHandler?
    private var errorHandler: RequestErrorHandler?
    
    let proxyClient: ProxyHttpClient
    
    init(url: URL, proxyClient: ProxyHttpClient) {
        self.url = url
        self.proxyClient = proxyClient
    }
    
    func send() {
        guard !sent else { return }
        sent = true
        proxyClient.sendRequest(to: url) { data, statusCode, error in
            self.data = data
            self.responseCode = statusCode
            let httpResponse = HttpResponse(code: statusCode, data: data)
            self.completion?(httpResponse)
            self.completionHandler?(httpResponse)
            // If error, also call error handler
            if let error = error as? HttpError {
                self.errorHandler?(error)
            }
        }
    }
    
    func setResponse(code: Int) {
        self.responseCode = code
    }
    
    func notifyIncomingData(_ data: Data) {
        if self.data == nil {
            self.data = Data()
        }
        self.data?.append(data)
    }
    
    func complete(error: HttpError?) {
        self.error = error
        self.errorHandler?(error ?? HttpError.unknown(code: -1, message: "Proxy error"))
    }
    
    func notifyPinnedCredentialFail() {
        pinnedCredentialFail = true
    }
    
    func getResponse(completionHandler: @escaping RequestCompletionHandler,
                     errorHandler: @escaping RequestErrorHandler) -> Self {
        self.completionHandler = completionHandler
        self.errorHandler = errorHandler
        return self
    }
}

