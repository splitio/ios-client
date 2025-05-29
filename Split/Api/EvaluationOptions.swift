//
//  EvaluationOptions.swift
//

import Foundation

@objc public class EvaluationOptions: NSObject {
    @objc public let properties: [String: Any]?

    @objc public init(properties: [String: Any]? = nil) {
        self.properties = properties
        super.init()
    }
}
