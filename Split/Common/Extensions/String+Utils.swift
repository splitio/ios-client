//
//  String+Utils.swift
//  Split
//
//  Created by Javier L. Avrudsky on 04/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

extension String {
    public func isEmpty() -> Bool {
        return (self.trimmingCharacters(in: .whitespacesAndNewlines) == "")
    }
    
    public func hasUpperCaseChar() -> Bool {
        
        if self.isEmpty() {
            return false
        }
        
        let validationRegex: NSRegularExpression? = try? NSRegularExpression(pattern: "^.*[A-Z]+.*$", options: [])
        if let regex = validationRegex {
            let range = regex.rangeOfFirstMatch(in: self, options: [], range: NSRange(location: 0,  length: self.count))
            return range.length > 0
        }
        return false
    }
    
}
