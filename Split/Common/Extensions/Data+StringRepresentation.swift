//
//  Data+StringDebug.swift
//  Split
//
//  Created by Javier L. Avrudsky on 6/11/18.
//

import Foundation

extension Data {
    var stringRepresentation: String {
        return String(data: self, encoding: .utf8) ?? "<< Invalid string representation >>"
    }

    var hexadecimalRepresentation: String {
        return map { String(format: "%02hhx", $0) + " " }.joined()
    }

    var binaryRepresentation: String {
        return map { String($0, radix: 2) + "(\($0)) " }.joined()
    }
}
