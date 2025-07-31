import XCTest
@testable import Split

class ProxyConfigurationTests: XCTestCase {
    
    func testProxyConfigurationInitialization() {
        // Given a valid proxy URL and CA certificate data
        let proxyUrlString = "https://proxy.example.com:8080"
        guard let proxyUrl = URL(string: proxyUrlString) else {
            XCTFail("Failed to create URL")
            return
        }
        
        let caCertificateData = "test-certificate-data".data(using: .utf8)!
        
        // When initializing a ProxyConfiguration
        do {
            let proxyConfig = try ProxyConfiguration(proxyURL: proxyUrl, caCertificateData: caCertificateData)
            
            // Then the configuration should be created with the correct values
            XCTAssertEqual(proxyConfig.proxyURL, proxyUrl)
            XCTAssertEqual(proxyConfig.caCertificateData, caCertificateData)
        } catch {
            XCTFail("ProxyConfiguration initialization failed with error: \(error)")
        }
    }
    
    func testProxyConfigurationWithInvalidURL() {
        // Given an invalid proxy URL (missing host)
        let invalidUrl = URL(string: "https://:8080")! // This URL has no host
        let caCertificateData = "test-certificate-data".data(using: .utf8)!
        
        // When initializing a ProxyConfiguration with an invalid URL
        // Then it should throw an error
        XCTAssertThrowsError(try ProxyConfiguration(proxyURL: invalidUrl, caCertificateData: caCertificateData)) { error in
            XCTAssertTrue(error is ProxyConfigurationError)
            XCTAssertEqual(error as? ProxyConfigurationError, .invalidProxyURL)
        }
    }
    
    func testProxyConfigurationWithEmptyCertificateData() {
        // Given a valid proxy URL but empty certificate data
        let proxyUrl = URL(string: "https://proxy.example.com:8080")!
        let emptyCertificateData = Data()
        
        // When initializing a ProxyConfiguration with empty certificate data
        // Then it should throw an error
        XCTAssertThrowsError(try ProxyConfiguration(proxyURL: proxyUrl, caCertificateData: emptyCertificateData)) { error in
            XCTAssertTrue(error is ProxyConfigurationError)
            XCTAssertEqual(error as? ProxyConfigurationError, .invalidCertificateData)
        }
    }
}
