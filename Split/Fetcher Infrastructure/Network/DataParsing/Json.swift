//
//  Json.swift
//  Split
//
//  Created by Javier L. Avrudsky on 6/13/18.
//

import Foundation

struct Json {
    private var data: Data?
    
    init(_ data: Data? = nil){
        self.data = data
    }
    
    func isNull() -> Bool { return data == nil }
    
    func decode<T>(_ type: T.Type) throws -> T? where T : Decodable {
        
        if self.isNull() {
            return nil
        }
        
        let decoder = JSONDecoder()
        do {
            let result = try decoder.decode(T.self, from: data!)
            return result
        } catch {
            throw error
        }
    }
}

// Static methods
extension Json {
    static func encodeToJson<T: Encodable>(_ data: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(data)
        return String(data: jsonData, encoding: .utf8)!
    }
    
    static func encodeFrom<T: Decodable>(json: String, to type: T.Type) throws -> T {
        let jsonData = json.data(using: .utf8)!
        let encoded = try JSON(jsonData).decode(type)
        return encoded!
    }
}

typealias JSON = Json
