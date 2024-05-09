//
//  Semver.swift
//  Split
//
//  Created by Gaston Thea on 09/05/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

enum SemverParseError: Error {
    case invalidVersionFormat(String)
}

class Semver: Equatable {
    
    private let kMetadataDelimiter: Character = "+"
    private let kPreReleaseDelimiter: Character = "-"
    private let kValueDelimiter: Character = "."
    
    private var major: Int64?
    private var minor: Int64?
    private var patch: Int64?
    private var preRelease: [String] = []
    private var isStable: Bool
    private var metadata: String?
    
    private let version: String

    static func build(version: String) -> Semver? {
        return try? Semver(version)
    }

    private init(_ version: String) throws {
        let vWithoutMetadata: String = try setAndRemoveMetadataIfExists(version)
        let vWithoutPreRelease: String = try setAndRemovePreReleaseIfExists(vWithoutMetadata)
        try setMajorMinorAndPatch(vWithoutPreRelease)
        self.version = setVersion()
    }

    func compare(to: Semver) {
        // TODO
    }

    func getVersion() -> String {
        return version
    }

    static func ==(lhs: Semver, rhs: Semver) -> Bool {
        return lhs.version == rhs.version
    }

    private func setAndRemoveMetadataIfExists(_ version: String) throws -> String {
        if let index = version.firstIndex(of: kMetadataDelimiter) {
            if let nextIndex = version.index(index, offsetBy: 1, limitedBy: version.endIndex) {
                metadata = version[...nextIndex]

                if let metadata = metadata, !metadata.isEmpty {
                    throw SemverParseError.invalidVersionFormat("Unable to convert to Semver, incorrect metadata")
                }
            
                return version[...index].asString()
            }
        } else {
            return version
        }
    }

    private func setAndRemovePreReleaseIfExists(_ vWithoutMetadata: String) throws -> String {
        // TODO
    }

    private func setMajorMinorAndPatch(_ version: String) throws {
        // TODO
    }

    private func setVersion() -> String {
        // TODO
    }
}
