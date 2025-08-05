import XCTest
@testable import Split

class BasicHttpExecutorTests: XCTestCase {
    func testExecuteRequest_httpSuccess_returnsDataAndStatusCode() {
        // Given: an HTTP URL and a dummy tunnel (stream task)
        let url = URL(string: "http://origin.example.com/test")!
        let tunnel = MockStreamTask()
        let executor = BasicHttpExecutor()
        let expectation = self.expectation(description: "HTTP request through tunnel completes")
        
        // When: executing the request
        executor.executeRequest(url: url, through: tunnel) { data, statusCode, error in
            // Then: should return data and 200 status
            XCTAssertNotNil(data)
            XCTAssertEqual(statusCode, 200)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testExecuteRequest_httpsSuccess_returnsDataAndStatusCode() {
        // Given: an HTTPS URL and a mock tunnel that supports TLS
        let url = URL(string: "https://origin.example.com/test")!
        let tunnel = MockTLSStreamTask()
        let executor = BasicHttpExecutor()
        let expectation = self.expectation(description: "HTTPS request through tunnel completes")
        
        // When: executing the HTTPS request
        executor.executeRequest(url: url, through: tunnel) { data, statusCode, error in
            // Then: should return data and 200 status
            XCTAssertNotNil(data)
            XCTAssertEqual(statusCode, 200)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testExecuteRequest_httpsWithoutTLSSupport_returnsError() {
        // Given: an HTTPS URL and a tunnel that doesn't support TLS
        let url = URL(string: "https://origin.example.com/test")!
        let tunnel = MockStreamTask() // Plain tunnel without TLS support
        let executor = BasicHttpExecutor()
        let expectation = self.expectation(description: "HTTPS request fails without TLS")
        
        // When: executing the HTTPS request
        executor.executeRequest(url: url, through: tunnel) { data, statusCode, error in
            // Then: should return error indicating TLS is required
            XCTAssertNil(data)
            XCTAssertEqual(statusCode, 0)
            XCTAssertNotNil(error)
            XCTAssertTrue(error!.localizedDescription.contains("TLS"))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }
}

// Mock stream tasks for testing
class MockStreamTask: URLSessionStreamTask {
    override func write(_ data: Data, timeout: TimeInterval, completionHandler: @escaping (Error?) -> Void) {
        // Simulate successful write for HTTP
        DispatchQueue.main.async {
            completionHandler(nil)
        }
    }
    
    override func readData(ofMinLength minBytes: Int, maxLength maxBytes: Int, timeout: TimeInterval, completionHandler: @escaping (Data?, Bool, Error?) -> Void) {
        // Simulate HTTP response
        let httpResponse = "HTTP/1.1 200 OK\r\nContent-Length: 13\r\n\r\nHello, World!"
        DispatchQueue.main.async {
            completionHandler(httpResponse.data(using: .utf8), false, nil)
        }
    }
    
    override var state: URLSessionTask.State {
        return .running
    }
}

class MockTLSStreamTask: URLSessionStreamTask {
    override func write(_ data: Data, timeout: TimeInterval, completionHandler: @escaping (Error?) -> Void) {
        // Simulate successful TLS write
        DispatchQueue.main.async {
            completionHandler(nil)
        }
    }
    
    override func readData(ofMinLength minBytes: Int, maxLength maxBytes: Int, timeout: TimeInterval, completionHandler: @escaping (Data?, Bool, Error?) -> Void) {
        // Simulate HTTPS response (after TLS handshake)
        let httpsResponse = "HTTP/1.1 200 OK\r\nContent-Length: 20\r\n\r\nSecure Hello, World!"
        DispatchQueue.main.async {
            completionHandler(httpsResponse.data(using: .utf8), false, nil)
        }
    }
    
    override var state: URLSessionTask.State {
        return .running
    }
}
