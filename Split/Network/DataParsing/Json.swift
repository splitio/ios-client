//
//  Json.swift
//  Split
//
//  Created by Javier L. Avrudsky on 6/13/18.
//

import Foundation

enum SplitEncodingError: Error {
    case unknown
}

protocol DynamicEncodable {
    func toJsonObject() -> Any
}

protocol DynamicDecodable {
    init(jsonObject: Any) throws
}

typealias DynamicCodable = DynamicDecodable & DynamicEncodable

struct Json {
    private var data: Data?

    init(_ data: Data? = nil) {
        self.data = data
    }

    func isNull() -> Bool { return data == nil }

    func decode<T>(_ type: T.Type) throws -> T? where T: Decodable {
        guard let data = data else {
            return nil
        }
        return try Self.decodeFrom(json: data, to: type)
    }

    /// Decode using a custom decoder function
    /// - Parameters:
    ///   - decoder: A function that takes Data and returns a decoded object of type T
    /// - Returns: The decoded object
    /// - Throws: Decoding errors if the JSON cannot be parsed
    func decodeWith<T>(_ decoder: (Data) throws -> T) throws -> T? {
        guard let data = data else {
            return nil
        }
        return try decoder(data)
    }

    func dynamicDecode<T>(_ type: T.Type) throws -> T? where T: DynamicDecodable {
        var obj: T?
        if let data = data {
            if let jsondObj = try JSONSerialization.jsonObject(
                with: data,
                options: []) as? [String: DynamicDecodable] {
                if let jsondObj = jsondObj as? DynamicDecodable {
                    obj = try T(jsonObject: jsondObj)
                }
            }
        }
        return obj
    }
}

// Static methods
extension Json {
    static func encodeToJson<T: Encodable>(_ data: T) throws -> String {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(data)
        guard let result = String(data: jsonData, encoding: .utf8) else {
            throw GenericError.jsonParsingFail
        }
        return result
    }

    static func decodeFrom<T: Decodable>(json: String, to type: T.Type) throws -> T {
        if let jsonData = json.data(using: .utf8) {
            return try decodeFrom(json: jsonData, to: type)
        }
        throw GenericError.jsonParsingFail
    }

    static func decodeFrom<T: Decodable>(json: Data, to type: T.Type) throws -> T {
        return try JSONDecoder().decode(T.self, from: json)
    }

    static func encodeToJsonData<T: Encodable>(_ data: T) throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(data)
    }

    static func dynamicEncodeToJson<T: DynamicEncodable>(_ data: T) throws -> String {
        let jsonData = try JSONSerialization.data(withJSONObject: data.toJsonObject(), options: [])
        guard let result = String(data: jsonData, encoding: .utf8) else {
            throw GenericError.jsonParsingFail
        }
        return result
    }

    static func dynamicEncodeToJsonData<T: DynamicEncodable>(_ data: T) throws -> Data {
        return try JSONSerialization.data(withJSONObject: data.toJsonObject(), options: [])
    }

    static func dynamicDecodeFrom<T: DynamicDecodable>(json: String, to type: T.Type) throws -> T {
        guard let jsonData = json.data(using: .utf8) else {
            throw GenericError.jsonParsingFail
        }
        let encoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
        return try T(jsonObject: encoded)
    }
}

typealias JSON = Json

class JsonWrapper {
    let encoder: JSONEncoder
    init() {
        self.encoder = JSONEncoder()
    }

    func encodeToJson<T: Encodable>(_ data: T) throws -> String {
        let jsonData = try encoder.encode(data)
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
}
