# Http

A lightweight, modular HTTP networking layer for Swift applications.

## Overview

The `Http` module provides a clean abstraction over `URLSession` for making HTTP requests. It supports both standard data requests and streaming connections, with built-in support for TLS certificate pinning.

## Features

- **Data Requests**: Standard HTTP requests with response handling
- **Streaming Requests**: Server-Sent Events (SSE) and long-lived connections
- **Certificate Pinning**: TLS/SSL pinning with SHA-256 and SHA-1 hash validation
- **Request Management**: Automatic request lifecycle management
- **Swift 6 Compatible**: Full `Sendable` conformance for safe concurrency

## Architecture

### Core Components

| Component | Description |
|-----------|-------------|
| `HttpClient` | Main entry point for making HTTP requests |
| `HttpRequest` | Base protocol for all request types |
| `HttpDataRequest` | Standard request/response operations |
| `HttpStreamRequest` | Long-lived streaming connections |
| `HttpSession` | Wrapper around `URLSession` |
| `HttpRequestManager` | Manages request lifecycle and delegate callbacks |

### Certificate Pinning

| Component | Description |
|-----------|-------------|
| `TlsPinChecker` | Validates server certificates against pinned credentials |
| `CredentialPin` | Represents a pinned certificate hash |
| `HostDomainFilter` | Matches hosts against pinned domains (supports wildcards) |

### Configuration

| Component | Description |
|-----------|-------------|
| `HttpSessionConfig` | Session-level configuration (timeouts, pinning) |
| `Endpoint` | Defines API endpoints with URL and method |

## Usage

### Basic Request

```swift
let client = DefaultHttpClient.shared
let endpoint = Endpoint(url: url, method: .get)

let request = try client.sendRequest(endpoint: endpoint, parameters: nil, headers: nil, body: nil)
request.getResponse { response in
    // Handle response
} errorHandler: { error in
    // Handle error
}
```

### With Certificate Pinning

```swift
let config = HttpSessionConfig.default
config.pinChecker = DefaultTlsPinChecker(pins: [
    CredentialPin(host: "*.example.com", hash: pinHash, algo: .sha256)
])

let client = DefaultHttpClient(configuration: config)
```

## Integration

This module is designed to be used as a dependency by higher-level networking layers. It intentionally avoids JSON parsing and business logic, focusing solely on HTTP transport concerns.

### Protocols for Integration

- `HttpAuthenticator`: Custom authentication challenge handling
- `HttpNotificationHandler`: Certificate pinning status notifications

## Requirements

- Swift 5.3+
- iOS 9.0+ / macOS 10.11+ / watchOS 7.0+ / tvOS 9.0+
