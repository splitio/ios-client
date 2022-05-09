//
//  Base64Utils.swift
//  Split
//
//  Created by Javier L. Avrudsky on 11/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class Base64Utils {
    static let kOffsetLenght = 4
    class func decodeBase64URL(base64: String?) -> String? {
        guard let base64 = base64 else {
            return nil
        }

        // Replace +
        let base64NoPlus = base64.replacingOccurrences(of: "-", with: "+")
        // Replace _
       let base64NoSlash = base64NoPlus.replacingOccurrences(of: "_", with: "/")
        var finalBase64 = base64NoSlash
        // = complement
        let mod4 = base64NoPlus.count % 4
        if mod4 > 0 {
            let appStr = String(repeating: "=", count: 4 - mod4)
            finalBase64 = "\(base64NoSlash)\(appStr)"
        }
        return Data(base64Encoded: finalBase64,
                    options: Data.Base64DecodingOptions.init(rawValue: 0))?.stringRepresentation
    }

    class func decodeBase64(_ base64: String?) -> Data? {
        guard let base64 = base64 else {
            return nil
        }

        // Replace +
        let base64NoPlus = base64.replacingOccurrences(of: "-", with: "+")
        // Replace _
       let base64NoSlash = base64NoPlus.replacingOccurrences(of: "_", with: "/")
        var finalBase64 = base64NoSlash
        // = complement
        let mod4 = base64NoPlus.count % 4
        if mod4 > 0 {
            let appStr = String(repeating: "=", count: 4 - mod4)
            finalBase64 = "\(base64NoSlash)\(appStr)"
        }
        return Data(base64Encoded: finalBase64,
                    options: Data.Base64DecodingOptions.init(rawValue: 0))
    }

    class func encodeToBase64(_ string: String) -> String {
        return Data(string.utf8).base64EncodedString(options: [])
    }
}
