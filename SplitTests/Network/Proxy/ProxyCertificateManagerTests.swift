import XCTest
@testable import Split

class ProxyCertificateManagerTests: XCTestCase {
    func testLoadCACertificateFromData_success() {
        // Given: A valid DER-encoded certificate (use a short dummy for now)
        let dummyCertBase64 = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7" // Not a real cert, just for test structure
        let certData = Data(base64Encoded: dummyCertBase64)!
        
        // When: Initializing the manager
        let manager = ProxyCertificateManager(caCertificateData: certData)
        
        // Then: The manager should store the certificate data
        XCTAssertEqual(manager.caCertificateData, certData)
    }
    
    func testCreateCustomTrustManager_returnsDelegate() {
        // Given
        let certData = Data([0x01, 0x02, 0x03])
        let manager = ProxyCertificateManager(caCertificateData: certData)
        
        // When
        let delegate = manager.createCustomTrustManager()
        
        // Then
        XCTAssertTrue(delegate is URLSessionDelegate)
    }
    
    func testValidateProxyServerCertificate_returnsFalseByDefault() {
        // Given
        let certData = Data([0x01, 0x02, 0x03])
        let manager = ProxyCertificateManager(caCertificateData: certData)
        // It's not possible to create a valid SecTrust without real certificates in a unit test
        // So we use a dummy value (nil-coalescing for compilation)
        let dummyTrust: SecTrust? = nil
        
        // When
        let result = manager.validateProxyServerCertificate(dummyTrust ?? SecTrustCreateWithCertificates as! SecTrust)
        
        // Then
        XCTAssertFalse(result)
    }

    // TODO: Add a real test using a test CA and leaf certificate for full trust evaluation
}

