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
}
