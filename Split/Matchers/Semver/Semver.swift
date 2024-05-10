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
    private var major: Int64
    private var minor: Int64
    private var patch: Int64
    private var preRelease: [String]?
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
            let preReleaseComponents = preReleaseData.split(separator: kValueDelimiter).map(String.init)

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
        let vParts = vWithoutPreRelease.split(separator: kValueDelimiter)

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
     * @return the value {@code 0} if {@code self == toCompare};
     * a value less than {@code 0} if {@code self < toCompare}; and
     * a value greater than {@code 0} if {@code self > toCompare}
     */
    func compare(to: Semver) -> Int {
        // TODO
        if (version == to.getVersion()) {
            return 0
        }
//
//        // Compare major, minor, and patch versions numerically
//        int result = Long.compare(mMajor, toCompare.mMajor);
//        if (result != 0) {
//            return result;
//        }
        // Compare major, minor, and patch versions numerically
//        let result = numericCompare(major, to.major)
        
//
//        result = Long.compare(mMinor, toCompare.mMinor);
//        if (result != 0) {
//            return result;
//        }
//
//        result = Long.compare(mPatch, toCompare.mPatch);
//        if (result != 0) {
//            return result;
//        }
//
//        if (!mIsStable && toCompare.mIsStable) {
//            return -1;
//        } else if (mIsStable && !toCompare.mIsStable) {
//            return 1;
//        }
//
//        // Compare pre-release versions lexically
//        int minLength = Math.min(mPreRelease.length, toCompare.mPreRelease.length);
//        for (int i = 0; i < minLength; i++) {
//            if (mPreRelease[i].equals(toCompare.mPreRelease[i])) {
//                continue;
//            }
//
//            if (isNumeric(mPreRelease[i]) && isNumeric(toCompare.mPreRelease[i])) {
//                return Long.compare(Long.parseLong(mPreRelease[i]), Long.parseLong(toCompare.mPreRelease[i]));
//            }
//
//            return mPreRelease[i].compareTo(toCompare.mPreRelease[i]);
//        }
//
//        // Compare lengths of pre-release versions
//        return Integer.compare(mPreRelease.length, toCompare.mPreRelease.length);
        return 0 //TODO
    }

    func getVersion() -> String {
        return version
    }

    static func ==(lhs: Semver, rhs: Semver) -> Bool {
        return lhs.version == rhs.version
    }

    private func setVersion() -> String {
        var toReturn = "\(major)\(kValueDelimiter)\(minor)\(kValueDelimiter)\(patch)"
        if let preRelease = preRelease, !preRelease.isEmpty {
            let numericPreRelease = preRelease.map { component -> String in
                if isNumeric(component) {
                    return String(Int64(component) ?? 0)
                }
                return component
            }
        }

        return toReturn
    }

    private func isNumeric(_ str: String) -> Bool {
        return Int(str) != nil || Double(str) != nil
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
}
