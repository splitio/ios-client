//
//  DataFolderFactory.swift
//  Split
//
//  Created by Javier L. Avrudsky on 07/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//
import Foundation

class DataFolderFactory {
    func createFrom(apiKey: String) -> String? {
        let kSaltLength = 29
        let kSaltPrefix = "$2a$10$"
        let kCharToFillSalt = "A"
        let sanitizedApiKey = sanitizeForFolderName(apiKey)
        var salt = kSaltPrefix
        if sanitizedApiKey.count >= kSaltLength - kSaltPrefix.count {
            let endIndex = sanitizedApiKey.index(sanitizedApiKey.startIndex,
                                                 offsetBy: kSaltLength - kSaltPrefix.count)
            salt.append(String(sanitizedApiKey[..<endIndex]))
        } else {
            salt.append(sanitizedApiKey)
            salt.append(contentsOf: String(repeating: kCharToFillSalt,
                                           count: (kSaltLength - kSaltPrefix.count) - sanitizedApiKey.count))
        }
        if let hash = JFBCrypt.hashPassword(sanitizedApiKey, withSalt: salt) {
            return sanitizeForFolderName(hash)
        }
        return nil
    }

    func sanitizeForFolderName(_ string: String) -> String {
        guard let regex: NSRegularExpression =
            try? NSRegularExpression(pattern: "[^a-zA-Z0-9]",
                                     options: NSRegularExpression.Options.caseInsensitive) else {
                fatalError("Regular expression not valid")
        }
        let range = NSRange(location: 0, length: string.count)
        return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
    }
}
