//
//  String+Utils.swift
//  Split
//
//  Created by Javier L. Avrudsky on 04/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

extension Substring {
    func asString() -> String {
        return String(self)
    }
}

extension String {
    func isEmpty() -> Bool {
        return (self.trimmingCharacters(in: .whitespacesAndNewlines) == "")
    }

    func hasUpperCaseChar() -> Bool {
        return self.lowercased() != self
    }

    var dataBytes: Data? {
        return self.data(using: .utf8)
    }

    // Make sure to need a new string when using this
    // function.
    func stringPrefix(to index: Int) -> String {
        return String(self.prefix(index))
    }

    // Same here
    func stringSuffix(from index: Int) -> String {
        return String(self.suffix(index))
    }

    func canPrefix(_ length: Int) -> Bool {
        return self.count >= length
    }

    func canSuffix(_ start: Int) -> Bool {
        return self.count > start
    }

    func suffix(starting start: Int) -> Substring {
        let startIdx = self.index(self.startIndex, offsetBy: start)
        return self[startIdx..<self.endIndex]
    }

    func contains(string: String, starting start: Int) -> Bool {
        if !self.canSuffix(start) {
            return false
        }

        return self.suffix(start).contains(string)
    }

    func matchRegex(_ regex: String) -> Bool {
        guard let regx = try? NSRegularExpression(pattern: regex) else {
            Logger.e("Error parsing regex \(regex)")
            return false
        }
        let range = NSRange(location: 0, length: self.utf8.count)
        return regx.firstMatch(in: self, range: range) != nil
    }
}
