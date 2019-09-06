//
//  Dictionary+JSON.swift
//  Pods
//
//  Created by Brian Sztamfater on 20/9/17.
//
//

import Foundation

extension Dictionary {

    func toJSONString() -> String? {
        let jsonData = try? JSONSerialization.data(withJSONObject: self, options: .init(rawValue: 0))
        if jsonData != nil {
            return String(data: jsonData!, encoding: .utf8)
        } else {
            return nil
        }
    }
}
