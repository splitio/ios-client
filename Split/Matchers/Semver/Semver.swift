//
//  Semver.swift
//  Split
//
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
    private var major: Int64
    private var minor: Int64
    private var patch: Int64
    private var preRelease: [String] = []
    private var isStable: Bool = true
    private var metadata: String?

    private var version: String = ""

    static func build(version: String) -> Semver? {
        return try? Semver(version)
    }

    private init(_ version: String) throws {
        // set and remove metadata if exists
        var vWithoutMetadata: String = ""
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

            vWithoutMetadata = String(versionSubstring)
        } else {
            vWithoutMetadata = version
        }

        // set and remove preRelease if exists
        var vWithoutPreRelease = ""
        if let index = vWithoutMetadata.firstIndex(of: kPreReleaseDelimiter) {
            let preReleaseDataIndex = vWithoutMetadata.index(after: index)

            guard preReleaseDataIndex < vWithoutMetadata.endIndex else {
                throw SemverParseError.invalidVersionFormat("Unable to convert to Semver, incorrect pre release data")
            }

            let preReleaseData = String(vWithoutMetadata[preReleaseDataIndex...])
            let preReleaseComponents = preReleaseData.split(separator: kValueDelimiter, omittingEmptySubsequences: false).map { String($0) }

            if preReleaseComponents.isEmpty || preReleaseComponents.contains(where: { $0.isEmpty }) {
                throw SemverParseError.invalidVersionFormat("Unable to convert to Semver, incorrect pre release data")
            }

            preRelease = preReleaseComponents
            isStable = false

            vWithoutPreRelease = String(vWithoutMetadata[..<index])
        } else {
            isStable = true
            vWithoutPreRelease = vWithoutMetadata
        }

        // set major, minor and patch
        let vParts = vWithoutPreRelease.split(separator: kValueDelimiter, omittingEmptySubsequences: false)

        if vParts.count != 3 {
            throw SemverParseError.invalidVersionFormat("Unable to convert to Semver, incorrect format: \(version)")
        }

        guard let major = Int64(vParts[0]), let minor = Int64(vParts[1]), let patch = Int64(vParts[2]) else {
            throw SemverParseError.invalidVersionFormat("Unable to convert to Semver, incorrect format: \(version)")
        }

        self.major = major
        self.minor = minor
        self.patch = patch

        // set version
        self.version = setVersion()
    }

    /**
     * Precedence comparison between 2 Semver objects.
     *
     * returns the value 0 if self == to;
     * a value less than 0 if self < to; and
     * a value greater than 0 if self > to
     */
    func compare(to: Semver) -> Int {
        if version == to.getVersion() {
            return 0
        }

        // Compare major, minor, and patch versions numerically
        var result = numericCompare(major, to.major)
        if result != 0 {
            return result
        }

        result = numericCompare(minor, to.minor)
        if result != 0 {
            return result
        }

        result = numericCompare(patch, to.patch)
        if result != 0 {
            return result
        }

        if !isStable && to.isStable {
            return -1
        } else if isStable && !to.isStable {
            return 1
        }

        // Compare pre-release versions lexically
        let minLength = min(preRelease.count, to.preRelease.count)
        for index in 0..<minLength {
            if preRelease[index] == to.preRelease[index] {
                continue
            }
            if let nPreRelease = Int64(preRelease[index]), let nToPreRelease = Int64(to.preRelease[index]) {
                return numericCompare(nPreRelease, nToPreRelease)
            }
            return stringCompare(preRelease[index], to.preRelease[index])
        }

        // Compare lengths of pre-release versions
        return numericCompare(Int64(preRelease.count), Int64(to.preRelease.count))
    }

    func getVersion() -> String {
        return version
    }

    static func == (lhs: Semver, rhs: Semver) -> Bool {
        return lhs.version == rhs.version
    }

    private func setVersion() -> String {
        var toReturn = "\(major)\(kValueDelimiter)\(minor)\(kValueDelimiter)\(patch)"
        if !preRelease.isEmpty {
            let numericPreRelease = preRelease.map { component -> String in
                if isNumeric(component) {
                    return String(Int64(component) ?? 0)
                }
                return component
            }

            toReturn += "\(kPreReleaseDelimiter)\(numericPreRelease.joined(separator: String(kPreReleaseDelimiter)))"
        }

        if let metadata = metadata, !metadata.isEmpty {
            toReturn += "\(kMetadataDelimiter)\(metadata)"
        }

        return toReturn
    }

    private func isNumeric(_ str: String) -> Bool {
        return Int64(str) != nil || Double(str) != nil
    }

    private func numericCompare(_ one: Int64, _ two: Int64) -> Int {
        if one < two {
            return -1
        } else if one > two {
            return 1
        } else {
            return 0
        }
    }

    private func stringCompare(_ one: String, _ two: String) -> Int {
        if one < two {
            return -1
        } else if one > two {
            return 1
        } else {
            return 0
        }
    }
}
