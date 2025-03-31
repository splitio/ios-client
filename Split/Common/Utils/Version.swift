//
//  Version.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/1/18.
//

import Foundation

class Version {
    private static let kSdkPlatform: String = "ios"
    private static let kVersion = "3.2.0-rc1"

    static var semantic: String {
        return kVersion
    }

    static var sdk: String {
        return "\(kSdkPlatform)-\(Version.semantic)"
    }
}
