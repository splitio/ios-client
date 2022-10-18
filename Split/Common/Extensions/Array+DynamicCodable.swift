//
//  Array+DynamicCodable.swift
//  Split
//
//  Created by Javier L. Avrudsky on 15/05/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

extension Array: DynamicEncodable where Element: DynamicEncodable {
    func toJsonObject() -> Any {
        return self.map({ $0.toJsonObject() })
    }
}

extension Array: DynamicDecodable where Element: DynamicDecodable {
    init(jsonObject: Any) throws {
        if let elements = jsonObject as? [Any] {
            self = try elements.map({ try Element(jsonObject: $0) })
        } else {
            Logger.i("DynamicDecodable: Could not parse objects")
            self = []
        }
    }
}
