//
//  Version.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/1/18.
//

import Foundation

class Version {
    private static let kSdkPlatform: String = "ios"
    private static let kVersion = "2.24.5-rc9"

    static var semantic: String {
        return kVersion
    }

    static var sdk: String {
        return "\(kSdkPlatform)-\(Version.semantic)"
    }
}
