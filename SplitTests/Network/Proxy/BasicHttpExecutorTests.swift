import XCTest
@testable import Split

class BasicHttpExecutorTests: XCTestCase {
    func testExecuteRequest_success_returnsDataAndStatusCode() {
        // Given: a GET URL and a dummy tunnel (stream task)
        let url = URL(string: "https://origin.example.com/test")!
        let tunnel = DummyStreamTask()
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
}

// DummyStreamTask for test contract
class DummyStreamTask: URLSessionStreamTask {}
