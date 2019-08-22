//
//  HttpResponse.swift
//  Split
//
//  Created by Javier L. Avrudsky on 5/23/18.
//  Based on code from Alamofire network library

import Foundation

// MARK: HttpDataResponse
struct HttpDataResponse<Value> {
    let request: URLRequest?
    let response: HTTPURLResponse?
    let error: Error? = nil
    let data: Data?
    let result: HttpResult<Value>

    init(request: URLRequest?, response: HTTPURLResponse?, data: Data?, result: HttpResult<Value>) {
        self.request = request
        self.response = response
        self.data = data
        self.result = result
    }
}

// MARK: HttpResult
enum HttpResult<Value> {
    case success(Value)
    case failure(Error)

    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    public var isFailure: Bool {
        return !isSuccess
    }

    public var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    public var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}

// MARK: Serialization
protocol HttpDataResponseSerializerProtocol {
    associatedtype SerializedObject
    var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> HttpResult<SerializedObject> { get }
}

struct HttpDataResponseSerializer<Value>: HttpDataResponseSerializerProtocol {
    typealias SerializedObject = Value

    var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> HttpResult<Value>

    init(serializeResponse: @escaping (URLRequest?, HTTPURLResponse?, Data?, Error?) -> HttpResult<Value>) {
        self.serializeResponse = serializeResponse
    }
}
