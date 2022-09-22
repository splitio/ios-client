//
//  Dictionary+DynamicCodable.swift
//  Split
//
//  Created by Javier L. Avrudsky on 15/05/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

extension Dictionary: DynamicEncodable where Key: Hashable, Value: DynamicEncodable {
    func toJsonObject() -> Any {
        let dic = self.mapValues({ $0.toJsonObject() })
        return dic
    }
}

extension Dictionary: DynamicDecodable where Key: Hashable, Value: DynamicDecodable {
    init(jsonObject: Any) throws {
        if let elements = jsonObject as? [Key: Any] {
            self = try elements.mapValues({ try Value.init(jsonObject: $0) })
        } else {
            Logger.i("DynamicDecodable: Could not parse objects")
            self = [:]
        }
    }
}
