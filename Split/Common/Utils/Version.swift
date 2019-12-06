//
//  Version.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/1/18.
//

import Foundation

class Version {
    private static let kSdkPlatform: String = "ios"
    private static let kBundleShortVersionField = "CFBundleShortVersionString"

    static var semantic: String {
        if let version =  Bundle(for: self).object(forInfoDictionaryKey: kBundleShortVersionField) as? String {
            return version
        }
        return "Unavailable"
    }

    static var sdk: String {
        return "\(kSdkPlatform)-\(Self.semantic)"
    }
}
