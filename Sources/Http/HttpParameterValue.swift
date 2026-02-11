//
//  HttpParameterValue.swift
//  Http
//
//  Sendable value type for query parameters (Swift 6 compatible; no Any).
//

import Foundation

/// A single value for an HTTP query parameter. Sendable and used by `HttpParameter` / `HttpParameters`.
public enum HttpParameterValue: Sendable {
    case string(String)
    case int(Int)
    case int64(Int64)
    case stringArray([String])
    case intArray([Int])
    case none

    /// Serializes this value for a query string: either one string or comma‑separated.
    public var queryStringValue: String? {
        switch self {
        case .string(let s): return s
        case .int(let i): return "\(i)"
        case .int64(let i): return "\(i)"
        case .stringArray(let a): return a.isEmpty ? nil : a.joined(separator: ",")
        case .intArray(let a): return a.isEmpty ? nil : a.map { "\($0)" }.joined(separator: ",")
        case .none: return nil
        }
    }
}
