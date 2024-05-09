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
    
    private var major: Int64? = nil
    private var minor: Int64? = nil
    private var patch: Int64? = nil
    private var preRelease: [String]? = nil
    private var isStable: Bool = true
    private var metadata: String? = nil
    
    private var version: String = ""

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
            let metadataIndex = version.index(after: index)

            guard metadataIndex < version.endIndex else {
                throw SemverParseError.invalidVersionFormat("Unable to convert to Semver, incorrect metadata")
            }

            let metadataString = String(version[metadataIndex...])

            if metadataString.isEmpty {
                throw SemverParseError.invalidVersionFormat("Unable to convert to Semver, incorrect metadata")
            }

            metadata = metadataString

            let versionSubstring = version[..<index]

            return String(versionSubstring)
        }

        return version
    }

    private func setAndRemovePreReleaseIfExists(_ vWithoutMetadata: String) throws -> String {
        if let index = vWithoutMetadata.firstIndex(of: kPreReleaseDelimiter) {
            let preReleaseDataIndex = vWithoutMetadata.index(after: index)

            guard preReleaseDataIndex < vWithoutMetadata.endIndex else {
                throw SemverParseError.invalidVersionFormat("Unable to convert to Semver, incorrect pre release data")
            }

            let preReleaseData = String(vWithoutMetadata[preReleaseDataIndex...])
            let preReleaseComponents = preReleaseData.split(separator: kValueDelimiter).map(String.init)

            if preReleaseComponents.isEmpty || preReleaseComponents.contains(where: { $0.isEmpty }) {
                throw SemverParseError.invalidVersionFormat("Unable to convert to Semver, incorrect pre release data")
            }

            preRelease = preReleaseComponents
            isStable = false

            return String(vWithoutMetadata[..<index])
        }

        isStable = true
        return vWithoutMetadata
    }

    private func setMajorMinorAndPatch(_ version: String) throws {
        let vParts = version.split(separator: kValueDelimiter)

        if vParts.count != 3 {
            // Log the error if needed
            print("Unable to convert to Semver, incorrect format: \(version)")
            throw SemverParseError.invalidVersionFormat("Unable to convert to Semver, incorrect format: \(version)")
        }

        guard let major = Int64(vParts[0]), let minor = Int64(vParts[1]), let patch = Int64(vParts[2]) else {
            throw SemverParseError.invalidVersionFormat("Unable to convert to Semver, incorrect format: \(version)")
        }

        self.major = major
        self.minor = minor
        self.patch = patch
    }

    private func setVersion() -> String {
        var toReturn = ""
        if let major = major {
            toReturn += "\(major)"
        }
        if let minor = minor {
            toReturn += "\(kValueDelimiter)\(minor)"
        }
        if let patch = patch {
            toReturn += "\(kValueDelimiter)\(patch)"
        }

        if let preRelease = preRelease, !preRelease.isEmpty {
            let numericPreRelease = preRelease.map { component -> String in
                if isNumeric(component) {
                    return String(Int64(component) ?? 0)
                }
                return component
            }

            toReturn += String(kPreReleaseDelimiter) + numericPreRelease.joined(separator: String(kValueDelimiter))
        }

        if let metadata = metadata, !metadata.isEmpty {
            toReturn += String(kMetadataDelimiter) + metadata
        }

        return toReturn
    }

    private func isNumeric(_ str: String) -> Bool {
        return Int(str) != nil || Double(str) != nil
    }
}
