//
//  FixtureGenerator.swift
//  SplitTests
//

import Foundation
import CommonCrypto

// Deterministic generator of splitChanges fixtures (FME-22007, section 6.4).
// Inputs are aggregates only: flag count, set count, flags with sets, sizes and
// condition counts. Every name and string in the output is generated from the
// seed. Output bytes depend only on the parameters: no system randomness, no
// hashing or dictionary order, no Date, and a hand-written serializer with a
// fixed key order.

struct FixtureParams: Equatable {
    let flags: Int
    let sets: Int
    let flagsWithSets: Int
    let maxSetsPerFlag: Int
    let meanBytes: Int
    let medianBytes: Int
    let maxBytes: Int
    let meanConditions: Double
    let maxConditions: Int
    let seed: UInt64
}

enum FixtureSize: String, CaseIterable {
    case small
    case medium
    case large

    func params(seed: UInt64) -> FixtureParams {
        switch self {
        case .small:
            return FixtureParams(flags: 177, sets: 2, flagsWithSets: 19, maxSetsPerFlag: 2,
                                 meanBytes: 1263, medianBytes: 1395, maxBytes: 2970,
                                 meanConditions: 1.5, maxConditions: 3, seed: seed)
        case .medium:
            return FixtureParams(flags: 1200, sets: 8, flagsWithSets: 600, maxSetsPerFlag: 3,
                                 meanBytes: 1400, medianBytes: 1390, maxBytes: 8000,
                                 meanConditions: 1.7, maxConditions: 8, seed: seed)
        case .large:
            return FixtureParams(flags: 4585, sets: 21, flagsWithSets: 3730, maxSetsPerFlag: 4,
                                 meanBytes: 1517, medianBytes: 1382, maxBytes: 23124,
                                 meanConditions: 1.9, maxConditions: 19, seed: seed)
        }
    }
}

struct FixtureResult {
    let url: URL
    let sha256: String
    let seed: UInt64
    let flagCount: Int
    let setCount: Int
    let meanFlagBytes: Double
    let medianFlagBytes: Int
    let maxFlagBytes: Int
}

/// SplitMix64: a small, fully specified PRNG so output is identical across runs and Swift versions.
struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniform in 0..<bound. Caller guarantees bound > 0.
    mutating func nextInt(_ bound: Int) -> Int {
        Int(next() % UInt64(bound))
    }

    /// Uniform in [0, 1).
    mutating func nextDouble() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }

    /// Standard normal via Box-Muller.
    mutating func nextGaussian() -> Double {
        let u1 = max(nextDouble(), 1e-300)
        let u2 = nextDouble()
        return (-2.0 * log(u1)).squareRoot() * cos(2.0 * Double.pi * u2)
    }
}

enum FixtureGenerator {

    static let defaultSeed: UInt64 = 22007

    private static let minFlagBytes = 300
    private static let letters = Array("abcdefghijklmnopqrstuvwxyz")
    /// A whitelist entry "k_xxxxxxxxxx" is 14 bytes quoted, plus one comma between entries.
    private static let keyEntryBytes = 15

    /// Hash of the file bytes, as lowercase hex (CommonCrypto, iOS 12 compatible).
    static func sha256Hex(of data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { raw in
            _ = CC_SHA256(raw.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func generate(size: FixtureSize, seed: UInt64, outputDir: URL) throws -> FixtureResult {
        try generate(size.params(seed: seed), outputDir: outputDir,
                     fileName: "fixture_\(size.rawValue)_\(seed).json")
    }

    static func generate(_ params: FixtureParams, outputDir: URL, fileName: String) throws -> FixtureResult {
        precondition(params.flags > 0, "flags must be positive")
        precondition(params.sets >= 1 && params.sets <= params.flagsWithSets,
                     "every set must be carried by at least one flag")
        precondition(params.flagsWithSets <= params.flags, "flagsWithSets cannot exceed flags")
        precondition(params.maxSetsPerFlag >= 1 && params.maxSetsPerFlag <= params.sets,
                     "maxSetsPerFlag must be within 1...sets")
        precondition(params.maxConditions >= 1 && params.meanConditions >= 1, "conditions must be at least 1")
        precondition(params.maxBytes > minFlagBytes && params.medianBytes > 0 && params.meanBytes > 0)

        var rng = SplitMix64(seed: params.seed)
        let setNames = uniqueNames(prefix: "s_", count: params.sets, rng: &rng)
        let flagNames = uniqueNames(prefix: "f_", count: params.flags, rng: &rng)
        let trafficType = "tt_" + randomLetters(6, &rng)

        // Which flags carry sets: a seeded partial Fisher-Yates shuffle of the indices.
        var order = Array(0..<params.flags)
        for i in stride(from: params.flags - 1, to: 0, by: -1) {
            order.swapAt(i, rng.nextInt(i + 1))
        }
        var carriesSets = [Bool](repeating: false, count: params.flags)
        for index in order.prefix(params.flagsWithSets) {
            carriesSets[index] = true
        }

        // Lognormal shape from mean and median. A mean below the median cannot be
        // lognormal; use a fixed sigma there and let the mean calibration decide.
        let continueProbability = 1.0 - 1.0 / params.meanConditions
        let mu = log(Double(params.medianBytes))
        let sigma = params.meanBytes > params.medianBytes
            ? (2.0 * log(Double(params.meanBytes) / Double(params.medianBytes))).squareRoot()
            : 0.35

        var drafts = [FlagDraft]()
        drafts.reserveCapacity(params.flags)
        var nextSetOrdinal = 0
        for i in 0..<params.flags {
            var conditionCount = 1
            while conditionCount < params.maxConditions && rng.nextDouble() < continueProbability {
                conditionCount += 1
            }
            var sets: [String]?
            if carriesSets[i] {
                // The first flags carrying sets cover every set in turn, so all S appear.
                let count = 1 + rng.nextInt(params.maxSetsPerFlag)
                var chosen = [nextSetOrdinal % params.sets]
                nextSetOrdinal += 1
                while chosen.count < count {
                    let candidate = rng.nextInt(params.sets)
                    if !chosen.contains(candidate) {
                        chosen.append(candidate)
                    }
                }
                sets = chosen.map { setNames[$0] }
            }
            let raw = exp(mu + sigma * rng.nextGaussian())
            let changeNumber = 1_600_000_000_000 + rng.nextInt(1_000_000_000)
            drafts.append(FlagDraft(name: flagNames[i], changeNumber: changeNumber,
                                    conditionCount: conditionCount, sets: sets, raw: raw))
        }

        // The largest draw becomes the capped flag: maxBytes, with the most conditions.
        var outlier = 0
        for i in 1..<params.flags where drafts[i].raw > drafts[outlier].raw {
            outlier = i
        }
        drafts[outlier].conditionCount = params.maxConditions

        // Bytes each flag takes with no keys and an empty label.
        let baseSizes = drafts.map { draft in
            utf8Count(serialize(spec(draft, trafficType: trafficType, keys: [], label: "")))
        }

        // Calibrate the scale so the sum of sizes is flags * meanBytes exactly.
        let goal = Double(params.flags) * Double(params.meanBytes)
        func total(_ scale: Double) -> Double {
            var sum = Double(params.maxBytes)
            for i in 0..<params.flags where i != outlier {
                sum += max(scaled(drafts[i].raw, scale, params), Double(baseSizes[i]))
            }
            return sum
        }
        var low = log(1e-6)
        var high = log(1e6)
        for _ in 0..<200 {
            let middle = (low + high) / 2
            if total(exp(middle)) < goal {
                low = middle
            } else {
                high = middle
            }
        }
        let scale = exp((low + high) / 2)

        // Fill each flag to its target: whole keys first, then a label for the remainder.
        var flagTexts = [String]()
        flagTexts.reserveCapacity(params.flags)
        var sizes = [Int]()
        sizes.reserveCapacity(params.flags)
        for i in 0..<params.flags {
            let target = i == outlier
                ? params.maxBytes
                : Int(scaled(drafts[i].raw, scale, params).rounded())
            var keys = [String]()
            var label = ""
            if target > baseSizes[i] {
                let extra = target - baseSizes[i]
                let keyCount = (extra + 1) / keyEntryBytes
                keys = (0..<keyCount).map { _ in "k_" + randomLetters(10, &rng) }
                let keyBytes = keyCount > 0 ? keyCount * keyEntryBytes - 1 : 0
                label = randomLetters(extra - keyBytes, &rng)
            }
            let text = serialize(spec(drafts[i], trafficType: trafficType, keys: keys, label: label))
            flagTexts.append(text)
            sizes.append(utf8Count(text))
        }

        let till = drafts.map { $0.changeNumber }.max() ?? 0
        let body = "{\"splits\":[" + flagTexts.joined(separator: ",") + "],\"since\":-1,\"till\":\(till)}"
        let data = Data(body.utf8)
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        let url = outputDir.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)

        let sortedSizes = sizes.sorted()
        let usedSets = Set(drafts.flatMap { $0.sets ?? [] })
        return FixtureResult(url: url,
                             sha256: sha256Hex(of: data),
                             seed: params.seed,
                             flagCount: drafts.count,
                             setCount: usedSets.count,
                             meanFlagBytes: Double(sizes.reduce(0, +)) / Double(sizes.count),
                             medianFlagBytes: sortedSizes[sortedSizes.count / 2],
                             maxFlagBytes: sortedSizes[sortedSizes.count - 1])
    }

    // MARK: - Drafts and serialization

    private struct FlagDraft {
        let name: String
        let changeNumber: Int
        var conditionCount: Int
        let sets: [String]?
        let raw: Double
    }

    private struct FlagSpec {
        let name: String
        let trafficType: String
        let changeNumber: Int
        let conditionCount: Int
        let sets: [String]?
        let keys: [String]
        let label: String
    }

    private static func spec(_ draft: FlagDraft, trafficType: String, keys: [String], label: String) -> FlagSpec {
        FlagSpec(name: draft.name, trafficType: trafficType, changeNumber: draft.changeNumber,
                 conditionCount: draft.conditionCount, sets: draft.sets, keys: keys, label: label)
    }

    /// Fixed key order. Every string is generated from [a-z0-9_], so only quoting is needed.
    private static func serialize(_ spec: FlagSpec) -> String {
        var text = "{\"name\":\(quoted(spec.name)),"
        text += "\"trafficTypeName\":\(quoted(spec.trafficType)),"
        text += "\"label\":\(quoted(spec.label)),"
        text += "\"status\":\"ACTIVE\",\"killed\":false,"
        text += "\"changeNumber\":\(spec.changeNumber),\"defaultTreatment\":\"off\","
        text += "\"conditions\":["
        let keyList = spec.keys.map { quoted($0) }.joined(separator: ",")
        for index in 0..<spec.conditionCount {
            if index > 0 {
                text += ","
            }
            let whitelist = index == 0 ? keyList : ""
            text += "{\"conditionType\":\"WHITELIST\","
            text += "\"matcherGroup\":{\"combiner\":\"AND\",\"matchers\":[{"
            text += "\"keySelector\":{\"trafficType\":\(quoted(spec.trafficType)),\"attribute\":null},"
            text += "\"matcherType\":\"WHITELIST\",\"negate\":false,"
            text += "\"userDefinedSegmentMatcherData\":null,"
            text += "\"whitelistMatcherData\":{\"whitelist\":[\(whitelist)]}}]},"
            text += "\"partitions\":[{\"treatment\":\"on\",\"size\":100},{\"treatment\":\"off\",\"size\":0}]}"
        }
        text += "]"
        if let sets = spec.sets {
            text += ",\"sets\":[" + sets.map { quoted($0) }.joined(separator: ",") + "]"
        }
        text += "}"
        return text
    }

    private static func quoted(_ value: String) -> String {
        "\"" + value + "\""
    }

    private static func utf8Count(_ text: String) -> Int {
        text.utf8.count
    }

    /// Size of one flag at a given scale, clamped to [minFlagBytes, maxBytes].
    private static func scaled(_ raw: Double, _ scale: Double, _ params: FixtureParams) -> Double {
        min(max(scale * raw, Double(minFlagBytes)), Double(params.maxBytes))
    }

    // MARK: - Names

    private static func randomLetters(_ count: Int, _ rng: inout SplitMix64) -> String {
        var out = ""
        out.reserveCapacity(count)
        for _ in 0..<count {
            out.append(letters[rng.nextInt(letters.count)])
        }
        return out
    }

    private static func uniqueNames(prefix: String, count: Int, rng: inout SplitMix64) -> [String] {
        var seen = Set<String>()
        var names = [String]()
        names.reserveCapacity(count)
        while names.count < count {
            let candidate = prefix + randomLetters(8, &rng)
            if seen.insert(candidate).inserted {
                names.append(candidate)
            }
        }
        return names
    }
}
