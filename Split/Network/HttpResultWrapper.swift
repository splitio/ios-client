//  Originally part of HttpDataResponse.swift
//  Bridges HttpResponse (from Http module) to the Json-based result wrapper
//  used by RestClient and the rest of the SDK.

import Foundation
#if !COCOAPODS
import Http
#endif

// MARK: HttpResultWrapper
enum HttpResultWrapper {
    case success(Json)
    case failure

    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    var value: Json? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
}

// MARK: HttpResponse + result
/// Provides the legacy `result` computed property so that existing
/// consumer code (RestClient, tests, etc.) continues to work unchanged.
extension HttpResponse {
    var result: HttpResultWrapper {
        if isSuccess {
            return .success(Json(data))
        }
        return .failure
    }
}
