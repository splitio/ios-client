# Split iOS SDK Proxy Implementation Plan

## Overview

This document provides a comprehensive implementation plan for adding proxy functionality to the Split iOS SDK, based on the Android SDK proxy implementation specification. The implementation will follow Test-Driven Development (TDD) principles with Red-Green-Refactor cycles and separate structural changes from behavioral changes (Tidy First approach).

## Architecture Overview

The iOS proxy implementation will mirror the Android architecture but use iOS/Swift conventions and integrate with URLSession instead of HttpURLConnection. The implementation consists of four main layers:

1. **Configuration Layer**: Proxy configuration and credential management
2. **Connection Layer**: Proxy connection establishment and tunnel creation  
3. **Execution Layer**: HTTP request execution through established tunnels
4. **Integration Layer**: Integration with existing URLSession infrastructure

## Current iOS SDK Analysis

### Existing HTTP Infrastructure
- **HttpClient Protocol**: Main HTTP interface with `DefaultHttpClient` implementation
- **HttpRequestManager**: Manages URLSession configuration and delegates
- **HttpSession**: Wraps URLSession for HTTP operations
- **RestClient**: High-level REST API client
- **OutdatedSplitProxyHandler**: Already exists for proxy compatibility handling

### Integration Points
- `SplitClientConfig`: Main configuration class (equivalent to Android's SplitClientConfig)
- `HttpSessionConfig`: HTTP session configuration
- `DefaultHttpClient`: Main HTTP client implementation
- `DefaultHttpRequestManager`: URLSession delegate and request management

## POC 1: End to End Functionality for TLS over TLS with Proxy CA Certificate

### Objective
Create a minimal viable product (MVP) that demonstrates core proxy functionality with TLS over TLS using a proxy CA certificate. This POC will validate the fundamental architecture and serve as a foundation for the full implementation.

### Scope
The POC will implement the minimal components needed to:
1. Establish an SSL connection to an HTTPS proxy using a custom CA certificate
2. Create an HTTP CONNECT tunnel through the proxy
3. Layer a second SSL connection through the tunnel to reach an HTTPS origin server
4. Execute a simple HTTP request and receive a response

### Components to Implement

#### POC.1 Minimal ProxyConfiguration
**File**: `Split/Network/Proxy/ProxyConfiguration.swift`

**Minimal Requirements**:
- Basic struct with proxy URL and CA certificate data
- Simple initializer (no builder pattern yet)
- Basic validation

```swift
struct ProxyConfiguration {
    let proxyURL: URL
    let caCertificateData: Data
    
    init(proxyURL: URL, caCertificateData: Data) throws {
        // Basic validation
    }
}
```

#### POC.2 Basic Certificate Manager
**File**: `Split/Network/Proxy/ProxyCertificateManager.swift`

**Minimal Requirements**:
- Load CA certificate from Data
- Create custom URLSessionDelegate for certificate validation
- Handle proxy server certificate validation only

```swift
class ProxyCertificateManager {
    private let caCertificateData: Data
    
    func createCustomTrustManager() -> URLSessionDelegate
    func validateProxyServerCertificate(_ trust: SecTrust) -> Bool
}
```

#### POC.3 Simple Tunnel Establisher
**File**: `Split/Network/Proxy/SimpleTunnelEstablisher.swift`

**Minimal Requirements**:
- Establish SSL connection to proxy
- Send basic HTTP CONNECT request (no authentication)
- Validate 200 OK response
- Return the established connection

```swift
class SimpleTunnelEstablisher {
    func establishTunnel(to targetHost: String, port: Int, through proxy: ProxyConfiguration) async throws -> URLSessionStreamTask
}
```

#### POC.4 Basic HTTP Executor
**File**: `Split/Network/Proxy/BasicHttpExecutor.swift`

**Minimal Requirements**:
- Send simple HTTP GET request through tunnel
- Parse basic HTTP response
- Return response data and status code

```swift
class BasicHttpExecutor {
    func executeRequest(url: URL, through tunnel: URLSessionStreamTask) async throws -> (data: Data, statusCode: Int)
}
```

#### POC.5 Integration Point
**File**: `Split/Network/Proxy/ProxyHttpClient.swift`

**Minimal Requirements**:
- Detect when proxy is configured
- Route single request through proxy system
- Fall back to direct connection if no proxy

```swift
class ProxyHttpClient {
    private let proxyConfig: ProxyConfiguration?
    
    func sendRequest(to url: URL) async throws -> (data: Data, statusCode: Int)
}
```

### POC Test Plan

#### Test Environment Setup
1. **Mock HTTPS Proxy Server**: Set up a test proxy with custom CA certificate
2. **Test HTTPS Origin Server**: Simple server to validate end-to-end connectivity
3. **Certificate Generation**: Create test CA and server certificates

#### Test Cases
1. **Direct Connection Test**: Verify existing functionality still works
2. **Proxy Connection Test**: Establish SSL connection to proxy with custom CA
3. **Tunnel Creation Test**: Successfully create CONNECT tunnel
4. **End-to-End Test**: Complete request through TLS-over-TLS tunnel
5. **Error Handling Test**: Handle proxy connection failures gracefully

### POC Success Criteria
1. ✅ SSL connection established to HTTPS proxy using custom CA certificate
2. ✅ HTTP CONNECT tunnel successfully created
3. ✅ Second SSL layer established through tunnel to origin server
4. ✅ HTTP request/response completed end-to-end
5. ✅ No breaking changes to existing HTTP functionality
6. ✅ Basic error handling for connection failures

### POC Timeline
**Estimated Duration**: 1-2 weeks

**Milestones**:
- Day 1-2: Certificate management and SSL connection to proxy
- Day 3-4: CONNECT tunnel establishment
- Day 5-6: TLS-over-TLS layering and origin connection
- Day 7-8: HTTP request execution and response handling
- Day 9-10: Integration testing and error handling

### POC Limitations
- No authentication support (Basic/Bearer/mTLS)
- No connection pooling or performance optimization
- No comprehensive error handling
- No integration with existing HttpClient architecture
- No streaming support
- Minimal configuration options

### Transition to Full Implementation
Once the POC is successful, the components will be:
1. **Refactored** to use proper builder patterns and configuration
2. **Extended** to support authentication methods
3. **Integrated** with existing HttpClient and URLSession infrastructure
4. **Optimized** for performance and memory management
5. **Hardened** with comprehensive error handling and logging

---

## Implementation Plan

### Phase 1: Core Configuration System

#### 1.1 Create ProxyConfiguration Struct
**File**: `Split/Network/Proxy/ProxyConfiguration.swift`

**Requirements**:
- Swift struct with builder pattern using method chaining
- Support for proxy URL (scheme, host, port)
- Support for credential providers
- Support for client certificates (Data objects for iOS)
- Support for CA certificates (Data objects for iOS)
- Validation logic for configuration completeness

**Test Requirements**:
- Test builder pattern functionality
- Test validation logic for required fields
- Test certificate data handling
- Test URL parsing and validation

#### 1.2 Create Credential Provider System
**Files**: 
- `Split/Network/Proxy/ProxyCredentialsProvider.swift` (protocol)
- `Split/Network/Proxy/BasicCredentialsProvider.swift`
- `Split/Network/Proxy/BearerCredentialsProvider.swift`

**Requirements**:
- Protocol defining credential provision interface
- Basic auth implementation with Base64 encoding
- Bearer token implementation with "Bearer " prefix
- Thread-safe credential access
- Secure credential storage considerations

**Test Requirements**:
- Test Basic auth encoding correctness
- Test Bearer token formatting
- Test thread safety of credential access
- Test credential validation

#### 1.3 Create HttpProxy Configuration Class
**File**: `Split/Network/Proxy/HttpProxy.swift`

**Requirements**:
- Legacy compatibility layer for existing configurations
- Support both old username/password and new credential provider patterns
- Integration with ProxyConfiguration
- Backward compatibility with any existing proxy configurations

**Test Requirements**:
- Test legacy configuration compatibility
- Test migration from old to new format
- Test configuration validation

### Phase 2: SSL/TLS Certificate Management

#### 2.1 Create Certificate Management System
**File**: `Split/Network/Proxy/ProxyCertificateManager.swift`

**Requirements**:
- Load certificates from Data objects (iOS equivalent of InputStreams)
- Create SecIdentity objects for client certificates
- Create SecTrust objects for CA validation
- Combine system CA certificates with custom proxy CAs
- Handle certificate chain validation

**Test Requirements**:
- Test certificate loading from Data
- Test SecIdentity creation for client certs
- Test SecTrust creation for CA validation
- Test certificate chain validation
- Test system CA + custom CA combination

#### 2.2 Create Custom URLSessionDelegate
**File**: `Split/Network/Proxy/ProxyURLSessionDelegate.swift`

**Requirements**:
- Implement URLSessionDelegate methods for certificate handling
- Support mTLS client certificate authentication
- Handle custom CA certificate validation
- Integrate with existing HttpRequestManager delegate chain
- Support both proxy and origin server certificate validation

**Test Requirements**:
- Test client certificate presentation
- Test custom CA validation
- Test certificate pinning compatibility
- Test delegate method implementations

### Phase 3: Proxy Tunnel Establishment

#### 3.1 Create SSL Proxy Tunnel Establisher
**File**: `Split/Network/Proxy/SslProxyTunnelEstablisher.swift`

**Requirements**:
- Establish SSL connections to HTTPS proxies
- Send HTTP CONNECT requests for tunnel creation
- Handle proxy authentication (Basic, Bearer, mTLS)
- Validate CONNECT response (expect 200 OK)
- Return established connection for further use
- Proper error handling and logging

**Test Requirements**:
- Test SSL connection establishment
- Test CONNECT request formatting
- Test authentication header inclusion
- Test response validation
- Test error scenarios (auth failure, connection failure)

#### 3.2 Create HTTP Over Tunnel Executor
**File**: `Split/Network/Proxy/HttpOverTunnelExecutor.swift`

**Requirements**:
- Execute HTTP requests through established tunnels
- Handle both HTTP and HTTPS origin servers
- Format raw HTTP requests with proper headers
- Parse raw HTTP responses
- Support streaming responses
- Manage connection lifecycle

**Test Requirements**:
- Test HTTP request formatting
- Test response parsing
- Test both HTTP and HTTPS origins
- Test streaming response handling
- Test connection management

### Phase 4: URLSession Integration

#### 4.1 Create Custom URLProtocol
**File**: `Split/Network/Proxy/ProxyURLProtocol.swift`

**Requirements**:
- Intercept HTTP requests when proxy is configured
- Route requests through proxy tunnel system
- Handle authentication challenges
- Support both data and streaming requests
- Maintain URLRequest/URLResponse compatibility
- Proper error propagation

**Test Requirements**:
- Test request interception
- Test proxy routing logic
- Test authentication handling
- Test response forwarding
- Test error handling

#### 4.2 Create HTTP Response Adapter
**File**: `Split/Network/Proxy/HttpResponseAdapter.swift`

**Requirements**:
- Adapt raw HTTP responses to URLResponse objects
- Maintain compatibility with existing HTTP client code
- Handle response headers and status codes
- Support streaming response data
- Preserve response metadata

**Test Requirements**:
- Test response adaptation accuracy
- Test header preservation
- Test status code mapping
- Test streaming data handling

### Phase 5: Integration with Existing Infrastructure

#### 5.1 Modify SplitClientConfig
**File**: `Split/Api/SplitClientConfig.swift`

**Requirements**:
- Add `HttpProxy?` property for proxy configuration
- Integrate proxy configuration in builder pattern
- Maintain backward compatibility
- Add proxy detection method `isProxy()`
- Update telemetry to report proxy usage

**Test Requirements**:
- Test proxy configuration integration
- Test backward compatibility
- Test proxy detection logic
- Test telemetry reporting

#### 5.2 Modify DefaultHttpClient
**File**: `Split/Network/HttpClient/HttpClient.swift`

**Requirements**:
- Detect proxy configuration during initialization
- Configure URLSession with proxy settings when needed
- Route requests through proxy system when configured
- Fall back to direct connections when no proxy
- Maintain existing API compatibility

**Test Requirements**:
- Test proxy detection and configuration
- Test request routing logic
- Test fallback behavior
- Test API compatibility

#### 5.3 Modify HttpRequestManager
**File**: `Split/Network/HttpClient/HttpRequestManager.swift`

**Requirements**:
- Integrate proxy certificate handling
- Configure URLSession delegates for proxy support
- Handle proxy authentication challenges
- Maintain existing certificate pinning functionality
- Support both proxy and direct connection modes

**Test Requirements**:
- Test certificate handling integration
- Test authentication challenge handling
- Test certificate pinning compatibility
- Test dual-mode operation

### Phase 6: Error Handling and Logging

#### 6.1 Create Proxy-Specific Error Types
**File**: `Split/Network/Proxy/ProxyError.swift`

**Requirements**:
- Define comprehensive proxy error types
- Include detailed error messages for debugging
- Support error recovery scenarios
- Integrate with existing HttpError system
- Provide actionable error information

**Test Requirements**:
- Test error type definitions
- Test error message clarity
- Test error recovery scenarios
- Test integration with existing error handling

#### 6.2 Add Comprehensive Logging
**Files**: Update existing proxy-related files

**Requirements**:
- Add detailed logging for proxy operations
- Include connection establishment logs
- Log authentication attempts and results
- Log tunnel creation and usage
- Use existing Logger system consistently

**Test Requirements**:
- Test logging output completeness
- Test log level appropriateness
- Test sensitive data protection in logs

### Phase 7: Performance and Memory Management

#### 7.1 Implement Connection Pooling
**File**: `Split/Network/Proxy/ProxyConnectionPool.swift`

**Requirements**:
- Pool established proxy connections for reuse
- Implement connection lifecycle management
- Handle connection timeout and cleanup
- Thread-safe connection access
- Integration with URLSession connection management

**Test Requirements**:
- Test connection reuse logic
- Test connection cleanup
- Test thread safety
- Test timeout handling

#### 7.2 Optimize Memory Management
**Files**: Update all proxy-related files

**Requirements**:
- Proper cleanup of SSL contexts and certificates
- Efficient handling of certificate Data objects
- Stream and buffer management for responses
- Avoid memory leaks in long-lived connections
- Use weak references where appropriate

**Test Requirements**:
- Test memory leak prevention
- Test resource cleanup
- Test long-lived connection handling

### Phase 8: Testing and Documentation

#### 8.1 Create Comprehensive Test Suite
**Files**: `SplitTests/Network/Proxy/` directory structure

**Requirements**:
- Unit tests for all proxy components
- Integration tests with existing HTTP infrastructure
- End-to-end tests with mock proxy servers
- Performance tests for proxy overhead
- Security tests for certificate handling

**Test Coverage Requirements**:
- Minimum 90% code coverage for proxy components
- All error scenarios covered
- All authentication methods tested
- All certificate configurations tested

#### 8.2 Create Documentation and Examples
**Files**: 
- Update existing documentation
- Create proxy configuration examples
- Add migration guide

**Requirements**:
- API documentation for all public interfaces
- Configuration examples for different proxy types
- Migration guide from direct connections
- Troubleshooting guide for common issues
- Performance impact documentation

## Implementation Guidelines

### TDD Approach
1. **Red**: Write failing test that defines small increment of functionality
2. **Green**: Implement minimum code to make test pass
3. **Refactor**: Improve structure while keeping tests passing
4. **Commit**: Only commit when all tests pass and no warnings exist

### Tidy First Principles
1. **Separate Changes**: Never mix structural and behavioral changes
2. **Structural First**: Make structural changes before behavioral changes
3. **Validate**: Run tests before and after structural changes
4. **Small Commits**: Use small, frequent commits with clear messages

### Code Quality Standards
- Eliminate duplication ruthlessly
- Express intent clearly through naming
- Keep methods small and focused
- Minimize state and side effects
- Use simplest solution that works

## Risk Mitigation

### Technical Risks
1. **SSL-over-SSL Complexity**: iOS URLSession may have limitations similar to Android
   - **Mitigation**: Research URLSession SSL capabilities early, consider custom socket implementation if needed

2. **Certificate Management**: iOS Security framework differences from Java
   - **Mitigation**: Create comprehensive certificate handling tests early

3. **URLProtocol Limitations**: Custom URLProtocol may not support all features
   - **Mitigation**: Prototype URLProtocol approach early, have fallback plan

### Integration Risks
1. **Backward Compatibility**: Breaking existing HTTP functionality
   - **Mitigation**: Comprehensive regression testing, feature flags for proxy functionality

2. **Performance Impact**: Proxy overhead affecting SDK performance
   - **Mitigation**: Performance benchmarking, connection pooling, lazy initialization

## Success Criteria

1. **Functional**: All proxy authentication methods work correctly
2. **Compatible**: No breaking changes to existing API
3. **Performant**: Proxy overhead < 10% of direct connection time
4. **Reliable**: No memory leaks or connection issues
5. **Maintainable**: Clean, well-tested, documented code
6. **Secure**: Proper certificate validation and credential handling

## Timeline Estimate

- **Phase 1-2**: Configuration and Certificate Management (1-2 weeks)
- **Phase 3**: Tunnel Establishment (1 week)
- **Phase 4**: URLSession Integration (1-2 weeks)
- **Phase 5**: Infrastructure Integration (1 week)
- **Phase 6-7**: Error Handling and Performance (1 week)
- **Phase 8**: Testing and Documentation (1 week)

**Total Estimated Time**: 6-8 weeks

## Dependencies

- iOS Security framework for certificate handling
- Existing URLSession infrastructure
- Current HttpClient and RestClient architecture
- OutdatedSplitProxyHandler integration
- Logger system for consistent logging
