//
//  SplitConfigurations.swift
//  Split
//
//  Created by Javier L. Avrudsky on 25/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

///
/// Model to hold Split Configurations value
///
/// Split configuration json structure is unknown, so standard native
/// encoding was not enough and some custom code was added
struct SplitConfigurations: Codable {
    
    var configurations: [String: String]
    
    subscript(treatment: String) -> String? {
        get {
            return configurations[treatment]
        }
        set {
            configurations[treatment] = newValue
        }
    }
    
    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        init?(intValue: Int) {
            self.init(stringValue: "")
            self.intValue = intValue
        }
        
        var debugDescription: String { return stringValue }
    }
    
    
    
    init(from decoder: Decoder) throws {
        configurations = [String: String]()
        do {
            let values = try decoder.container(keyedBy: DynamicCodingKeys.self)
            for key in values.allKeys {
                if let container = try? values.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: key) {
                    // Parsing from server
                    let config: [String: Any] = decodeKeyedContainer(container)
                    if let jsonData = try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted) {
                        let jsonString = String(data: jsonData, encoding: .utf8)?.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: " ", with: "")
                        self.configurations[key.stringValue] = jsonString
                    }
                } else if let string = try? values.decode(String.self, forKey: key) {
                    // Parsing from disk
                    self.configurations[key.stringValue] = string
                } else {
                    Logger.e("Unable to parse Split Configurations values from server")
                }
            }
        } catch  {
            print(error)
        }
    }
    
    private func decodeKeyedContainer<K: CodingKey>(_ values: KeyedDecodingContainer<K>) -> [String: Any] {
        var config: [String: Any] = [String: Any]()

        for key in values.allKeys {
            if let container = try? values.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: key) {
                config[key.stringValue] = decodeKeyedContainer(container)
            } else if let container = try? values.nestedUnkeyedContainer(forKey: key) {
                config[key.stringValue] = decodeUnkeyedContainer(container)
            } else if let double = try? values.decode(Double.self, forKey: key) {
                config[key.stringValue] = double
            } else if let string = try? values.decode(String.self, forKey: key) {
                config[key.stringValue] = string
            } else if let integer = try? values.decode(Int.self, forKey: key) {
                config[key.stringValue] = integer
            } else if let boolean = try? values.decode(Bool.self, forKey: key) {
                config[key.stringValue] = boolean
            } else {
                Logger.e("Unexpected type when parsing json map in Split Configurations from server for: \(key)")
            }
        }
        return config
    }

    private func decodeUnkeyedContainer(_ values: UnkeyedDecodingContainer) -> [Any] {
        var config: [Any] = [Any]()
        var mutableValues = values
        while !mutableValues.isAtEnd {
            if let container = try? mutableValues.nestedContainer(keyedBy: DynamicCodingKeys.self) {
                config.append(decodeKeyedContainer(container))
            } else if let container = try? mutableValues.nestedUnkeyedContainer() {
                config.append(decodeUnkeyedContainer(container))
            } else if let double = try? mutableValues.decode(Double.self) {
                config.append(double)
            } else if let string = try? mutableValues.decode(String.self) {
                config.append(string)
            } else if let integer = try? mutableValues.decode(Int.self) {
                config.append(integer)
            } else if let boolean = try? mutableValues.decode(Bool.self) {
                config.append(boolean)
            } else {
                Logger.e("Unexpected type when parsing json array in Split Configurations from server")
            }
        }
        return config
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        for (key, value) in configurations {
            let json = value.replacingOccurrences(of: "\\", with: "")
            try container.encode(json, forKey: DynamicCodingKeys(stringValue: key)!)
        }
    }
}
