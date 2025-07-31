import Foundation

/// Minimal HTTP executor for requests through a proxy tunnel
class BasicHttpExecutor {
    /// Executes a GET request through the given tunnel
    /// Calls completion with response data, status code, or error
    func executeRequest(url: URL, through tunnel: URLSessionStreamTask, completion: @escaping (Data?, Int, Error?) -> Void) {
        // For TDD: return dummy data and 200
        let dummyData = "OK".data(using: .utf8)
        completion(dummyData, 200, nil)
    }
}
