//
//  HttpDataResponse.swift
//  Split
//
//  Created by Javier L. Avrudsky on 5/23/18.
//  Initially based on Alamofire network library API

import Foundation

// MARK: HttpDataResponse
struct HttpDataResponse<Value> {
    let error: Error? = nil
    let data: Data?
    let result: HttpResult<Value>

    init(data: Data?, result: HttpResult<Value>) {
        self.data = data
        self.result = result
    }
}

// MARK: HttpResult
enum HttpResult<Value> {
    case success(Value)
    case failure(Error)

    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    var isFailure: Bool {
        return !isSuccess
    }

    var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}

// MARK: Serialization
protocol HttpDataResponseSerializer {
    associatedtype SerializedObject
    var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> HttpResult<SerializedObject> { get }
}

struct HttpJsonDataResponseSerializer<Value>: HttpDataResponseSerializer {
    typealias SerializedObject = Value

    var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> HttpResult<Value>

    init(serializeResponse: @escaping (URLRequest?, HTTPURLResponse?, Data?, Error?) -> HttpResult<Value>) {
        self.serializeResponse = serializeResponse
    }
}
