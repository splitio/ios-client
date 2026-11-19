//
//  SplitsTopLevelScannerTest.swift
//  SplitTests
//

import XCTest
@testable import Split

// The top-level-fields scanner must give exactly the result of the JSONSerialization
// path (`getSplitUsingJSONSerialization`) for every body, or fall back to it. Every test compares both paths of
// SplitsSerialDecoder.getSplit field by field (strings by UTF-8 bytes, not by Swift equality).
class SplitsTopLevelScannerTest: XCTestCase {

    private var savedLevel: LogLevel!

    override func setUp() {
        savedLevel = Logger.shared.level
        Logger.shared.level = .none
    }

    override func tearDown() {
        Logger.shared.level = savedLevel
    }

    // MARK: - Helpers

    /// Field-wise view of a decoded Split. Strings are compared as UTF-8 bytes, sets as sorted byte lists.
    private struct Snapshot: Equatable {
        let name: [UInt8]?
        let trafficType: [UInt8]?
        let status: Int?
        let sets: [[UInt8]]?
        let killed: Bool?
        let json: [UInt8]
    }

    private func snapshot(_ split: Split) -> Snapshot {
        Snapshot(name: split.name.map { Array($0.utf8) },
                 trafficType: split.trafficTypeName.map { Array($0.utf8) },
                 status: split.status?.rawValue,
                 sets: split.sets.map { $0.map { Array($0.utf8) }.sorted { $0.lexicographicallyPrecedes($1) } },
                 killed: split.killed,
                 json: Array(split.json.utf8))
    }

    /// nil means the body was dropped (getSplit threw).
    private func outcome(_ body: String, scanner: Bool) -> Snapshot? {
        let decoder = SplitsSerialDecoder(cipher: nil)
        let split = scanner ? try? decoder.getSplit(body) : try? decoder.getSplitUsingJSONSerialization(body)
        return split.map(snapshot)
    }

    /// JSONSerialization-only decode with the same drop-on-failure behavior as `SplitsSerialDecoder.decode`.
    private func referenceDecode(_ list: [String], cipher: Cipher?) -> [Snapshot] {
        let decoder = SplitsSerialDecoder(cipher: nil)
        return list.compactMap { json in
            try? decoder.getSplitUsingJSONSerialization(cipher?.decrypt(json) ?? json)
        }.map(snapshot)
    }

    private func accepted(_ body: String) -> Bool {
        if case .fields = SplitsTopLevelScanner.scan(body) {
            return true
        }
        return false
    }

    private func describe(_ body: String) -> String {
        let text = body.count > 300 ? String(body.prefix(300)) + "..." : body
        return text.debugDescription
    }

    /// Asserts both paths agree and returns the shared outcome.
    @discardableResult
    private func assertSame(_ body: String, file: StaticString = #filePath, line: UInt = #line) -> Snapshot? {
        let current = outcome(body, scanner: false)
        let scanner = outcome(body, scanner: true)
        XCTAssertEqual(current, scanner, "paths differ for body \(describe(body))", file: file, line: line)
        return current
    }

    private func assertAccepted(_ body: String, file: StaticString = #filePath, line: UInt = #line) {
        assertSame(body, file: file, line: line)
        XCTAssertTrue(accepted(body), "scanner fell back on \(describe(body))", file: file, line: line)
    }

    private func assertFallback(_ body: String, file: StaticString = #filePath, line: UInt = #line) {
        assertSame(body, file: file, line: line)
        XCTAssertFalse(accepted(body), "scanner accepted \(describe(body))", file: file, line: line)
    }

    private func flag(name: String = "\"f1\"", tt: String = "\"user\"", status: String = "\"ACTIVE\"",
                      killed: String = "false", sets: String? = "[\"a\",\"b\"]",
                      extra: String = "\"conditions\":[]") -> String {
        var members = ["\"name\":\(name)", "\"trafficTypeName\":\(tt)", "\"status\":\(status)",
                       "\"killed\":\(killed)"]
        if let sets = sets {
            members.append("\"sets\":\(sets)")
        }
        if !extra.isEmpty {
            members.append(extra)
        }
        return "{" + members.joined(separator: ",") + "}"
    }

    private let base = "{\"name\":\"f1\",\"trafficTypeName\":\"user\",\"status\":\"ACTIVE\",\"killed\":false,"
        + "\"sets\":[\"a\",\"b\"],\"conditions\":[]}"

    private func fixtureBodies(size: FixtureSize) throws -> [String] {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("SplitsTopLevelScannerTest-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let result = try FixtureGenerator.generate(size: size, seed: FixtureGenerator.defaultSeed, outputDir: dir)
        let text = try String(contentsOf: result.url, encoding: .utf8)
        let prefix = "{\"splits\":["
        XCTAssertTrue(text.hasPrefix(prefix))
        guard let end = text.range(of: "],\"since\"", options: .backwards) else {
            XCTFail("fixture tail not found")
            return []
        }
        let inner = String(text[text.index(text.startIndex, offsetBy: prefix.count)..<end.lowerBound])
        let parts = inner.components(separatedBy: ",{\"name\":")
        var bodies = [String]()
        for (index, part) in parts.enumerated() {
            bodies.append(index == 0 ? part : "{\"name\":" + part)
        }
        XCTAssertEqual(bodies.count, result.flagCount)
        return bodies
    }

    // MARK: - 1. Differential on the fixture

    func test_fixture_largeDifferential_allFlagsIdentical_scannerAccepts() throws {
        let bodies = try fixtureBodies(size: .large)
        XCTAssertEqual(bodies.count, 4585)
        var compared = 0
        var acceptedCount = 0
        var mismatches = [String]()
        for body in bodies {
            let current = outcome(body, scanner: false)
            let scanner = outcome(body, scanner: true)
            compared += 1
            if current == nil || current != scanner {
                mismatches.append(describe(body))
            }
            if accepted(body) {
                acceptedCount += 1
            }
        }
        print("SCANNER_FIXTURE compared=\(compared) accepted=\(acceptedCount) fallback=\(compared - acceptedCount)")
        XCTAssertEqual(compared, 4585)
        XCTAssertEqual(mismatches, [])
        XCTAssertGreaterThanOrEqual(Double(acceptedCount) / Double(compared), 0.99,
                                    "scanner accepted only \(acceptedCount) of \(compared)")
    }

    func test_fixture_scannerValues_matchTheFixtureGenerator() throws {
        let bodies = try fixtureBodies(size: .small)
        var withSets = 0
        for body in bodies {
            guard case .fields(let fields) = SplitsTopLevelScanner.scan(body) else {
                return XCTFail("fell back on \(describe(body))")
            }
            XCTAssertTrue(fields.name.hasPrefix("f_"))
            XCTAssertTrue(fields.trafficType.hasPrefix("tt_"))
            XCTAssertEqual(fields.status, .active)
            XCTAssertFalse(fields.killed)
            if let sets = fields.sets {
                withSets += 1
                XCTAssertTrue(sets.allSatisfy { $0.hasPrefix("s_") })
            }
        }
        XCTAssertEqual(withSets, 19)
    }

    // MARK: - 2. Hand-written edge cases

    func test_base_isAccepted_withExpectedValues() {
        guard case .fields(let fields) = SplitsTopLevelScanner.scan(base) else {
            return XCTFail("fell back")
        }
        XCTAssertEqual(fields.name, "f1")
        XCTAssertEqual(fields.trafficType, "user")
        XCTAssertEqual(fields.status, .active)
        XCTAssertEqual(fields.sets, Set(["a", "b"]))
        XCTAssertFalse(fields.killed)
        assertAccepted(base)
    }

    func test_escapesInName_fallBack_andKeepDecodedValue() {
        let bodies = [flag(name: "\"a\\\"b\""), flag(name: "\"a\\\\b\""), flag(name: "\"a\\nb\""),
                      flag(name: "\"a\\u0041b\""), flag(name: "\"a\\/b\""), flag(name: "\"a\\tb\"")]
        let expected = ["a\"b", "a\\b", "a\nb", "aAb", "a/b", "a\tb"]
        for (body, name) in zip(bodies, expected) {
            assertFallback(body)
            XCTAssertEqual(outcome(body, scanner: true)?.name, Array(name.utf8))
        }
    }

    func test_escapesInOtherFields_fallBack() {
        assertFallback(flag(tt: "\"us\\u0065r\""))
        assertFallback(flag(status: "\"ACT\\u0049VE\""))
        assertFallback(flag(sets: "[\"a\",\"b\\u0063\"]"))
        assertFallback(flag(sets: "[\"a\\\"\"]"))
    }

    func test_unicodeNames_multibyteAndEmoji_areAcceptedAndIdentical() {
        for name in ["ñandú", "日本語フラグ", "rocket🚀flag", "e\u{301}", "\u{FFFE}x", "x\u{2028}y", "𝄞"] {
            let body = flag(name: "\"\(name)\"", tt: "\"tté\"", sets: "[\"sé\",\"s😀\"]")
            assertAccepted(body)
            XCTAssertEqual(outcome(body, scanner: true)?.name, Array(name.utf8))
        }
    }

    func test_unicodeEscapes_surrogatePair_fallsBack() {
        let body = flag(name: "\"x\\ud83d\\ude00\"")
        assertFallback(body)
        XCTAssertEqual(outcome(body, scanner: true)?.name, Array("x😀".utf8))
    }

    func test_loneSurrogateEscape_isDropped_inBothModes() {
        XCTAssertNil(assertSame(flag(name: "\"x\\ud83d\"")))
        XCTAssertNil(assertSame(flag(extra: "\"x\":\"\\ude00\"")))
        XCTAssertNil(assertSame(flag(extra: "\"x\":\"\\ud83dz\"")))
    }

    func test_validSurrogatePairAndEscapes_inSkippedStrings_areAccepted() {
        assertAccepted(flag(extra: "\"x\":\"\\ud83d\\ude00 \\\" \\\\ \\/ \\b\\f\\n\\r\\t \\u0000 \\u00e9\""))
    }

    func test_loneSurrogateBoundaries_inSkippedStrings_fallBackAndAreDropped() {
        for unit in ["d800", "dbff", "dc00", "dfff"] {
            let body = flag(extra: "\"x\":\"\\u\(unit)\",\"y\":1")
            XCTAssertFalse(accepted(body), unit)
            XCTAssertNil(assertSame(body), unit)
        }
    }

    func test_surrogatePairBoundaries_inSkippedStrings_areAccepted() {
        for pair in ["\\ud800\\udc00", "\\ud800\\udfff", "\\udbff\\udc00", "\\udbff\\udfff"] {
            assertAccepted(flag(extra: "\"x\":\"\(pair)\""))
        }
    }

    func test_surrogatePairBeforeClosingQuote_keepsLaterKeysInSync() {
        let body = flag(extra: "\"x\":\"a\\ud83d\\ude00\",\"y\":[1],\"z\":\"\\ud83d\\ude00\"")
        assertAccepted(body)
        XCTAssertEqual(outcome(body, scanner: true)?.name, Array("f1".utf8))
    }

    // A skipped value is at depth 1, each container adds one, and a container at depth 100 falls back:
    // 99 nested containers are accepted, 100 are not.
    func test_nestingLimit_isExact_forObjectsAndArrays() {
        func nested(_ levels: Int, object: Bool) -> String {
            let open = object ? "{\"k\":" : "["
            let close = object ? "}" : "]"
            return String(repeating: open, count: levels - 1) + (object ? "{}" : "[]")
                + String(repeating: close, count: levels - 1)
        }
        for object in [true, false] {
            assertAccepted(flag(extra: "\"x\":" + nested(99, object: object)))
            assertFallback(flag(extra: "\"x\":" + nested(100, object: object)))
            assertFallback(flag(extra: "\"x\":" + nested(101, object: object)))
        }
    }

    func test_duplicateTopLevelKeys_fallBack_firstWins() {
        let dups: [(String, String)] = [
            ("name", "\"name\":\"f2\""),
            ("trafficTypeName", "\"trafficTypeName\":\"other\""),
            ("status", "\"status\":\"ARCHIVED\""),
            ("killed", "\"killed\":true"),
            ("sets", "\"sets\":[\"z\"]")
        ]
        for (_, dup) in dups {
            let body = String(base.dropLast()) + "," + dup + "}"
            assertFallback(body)
            let front = "{" + dup + "," + base.dropFirst()
            assertFallback(front)
        }
        let first = outcome(String(base.dropLast()) + ",\"name\":\"f2\"}", scanner: true)
        XCTAssertEqual(first?.name, Array("f1".utf8))
        let front = outcome("{\"name\":\"f2\"," + base.dropFirst(), scanner: true)
        XCTAssertEqual(front?.name, Array("f2".utf8))
    }

    func test_duplicateOfUntrackedKey_isAccepted() {
        assertAccepted(flag(extra: "\"x\":1,\"x\":2"))
    }

    func test_nestedKeysWithTrackedNames_areNotMistakenForTopLevel() {
        let nested = "\"conditions\":[{\"name\":\"nn\",\"killed\":true,\"status\":\"ARCHIVED\","
            + "\"trafficTypeName\":\"nt\",\"sets\":[\"z\"],\"inner\":{\"name\":\"deep\",\"killed\":true}}]"
        let body = flag(extra: nested)
        assertAccepted(body)
        let out = outcome(body, scanner: true)
        XCTAssertEqual(out?.name, Array("f1".utf8))
        XCTAssertEqual(out?.killed, false)
        XCTAssertEqual(out?.sets?.count, 2)
        // Tracked keys only nested: the top level is missing them, the body is dropped by both.
        let onlyNested = "{\"x\":{" + String(base.dropFirst())
        XCTAssertNil(assertSame(onlyNested))
        XCTAssertNil(assertSame("{\"conditions\":[" + base + "]}"))
    }

    func test_keyOrderPermutations_areAllAccepted() {
        let members = ["\"name\":\"f1\"", "\"trafficTypeName\":\"user\"", "\"status\":\"active\"",
                       "\"killed\":true", "\"sets\":[\"a\"]", "\"conditions\":[{\"x\":[1,2]}]"]
        var count = 0
        func permute(_ items: [String], _ chosen: [String]) {
            if items.isEmpty {
                assertAccepted("{" + chosen.joined(separator: ",") + "}")
                count += 1
                return
            }
            for index in items.indices {
                var rest = items
                let item = rest.remove(at: index)
                permute(rest, chosen + [item])
            }
        }
        permute(members, [])
        XCTAssertEqual(count, 720)
    }

    func test_nestedValuesWithStructuralCharactersInStrings() {
        let extras = [
            "\"x\":\"}{][,:\"",
            "\"x\":[\"]\",\"[\",\"\\\"}\"]",
            "\"x\":{\"k}\":\"v{\",\"k2\":[\"a,b\",\"c:d\"]}",
            "\"x\":\"\\\\\"",
            "\"x\":\"\\\\\\\"\"",
            "\"x\":[[],[[]],{}]",
            "\"x\":[{\"a\":{\"b\":{\"c\":[{}]}}}]",
            "\"x\":\"é😀\""
        ]
        for extra in extras {
            assertAccepted(flag(extra: extra))
            assertAccepted("{" + extra + "," + base.dropFirst())
        }
    }

    func test_escapedKeys_fallBack() {
        assertFallback("{\"\\u006eame\":\"f2\"," + base.dropFirst())
        assertFallback(flag(extra: "\"a\\\"b\":1"))
        assertFallback(flag(extra: "\"\\u0061\":1"))
    }

    func test_emptySets_arrayIsEmptySet() {
        let body = flag(sets: "[]")
        assertAccepted(body)
        XCTAssertEqual(outcome(body, scanner: true)?.sets, [])
    }

    func test_setsMissingOrNull_isNilSets() {
        let missing = flag(sets: nil)
        assertAccepted(missing)
        XCTAssertNotNil(outcome(missing, scanner: true))
        XCTAssertNil(outcome(missing, scanner: true)?.sets)
        let null = flag(sets: "null")
        assertAccepted(null)
        XCTAssertNotNil(outcome(null, scanner: true))
        XCTAssertNil(outcome(null, scanner: true)?.sets)
    }

    func test_setsWithNonStringsOrOtherTypes_matchCurrent() {
        for sets in ["[1,2]", "[\"a\",1]", "[1,\"a\"]", "[null]", "[[\"a\"]]", "[{}]", "\"a\"", "1", "{}", "true",
                     "[\"a\",]", "[,\"a\"]", "[\"a\" \"b\"]", "[\"a\"", "[", "[\"a\",\"a\"]", "[\"a\",null]"] {
            assertSame(flag(sets: sets))
        }
        XCTAssertNil(outcome(flag(sets: "[1,2]"), scanner: false)?.sets)
        XCTAssertNil(outcome(flag(sets: "[\"a\",1]"), scanner: false)?.sets)
        XCTAssertNotNil(outcome(flag(sets: "[1,2]"), scanner: false))
        assertAccepted(flag(sets: "[\"a\",\"a\"]"))
        XCTAssertEqual(outcome(flag(sets: "[\"a\",\"a\"]"), scanner: true)?.sets?.count, 1)
    }

    func test_killed_onlyLiteralBooleansAreAccepted() {
        assertAccepted(flag(killed: "true"))
        assertAccepted(flag(killed: "false"))
        XCTAssertEqual(outcome(flag(killed: "true"), scanner: true)?.killed, true)
        for killed in ["0", "1", "null", "\"true\"", "\"false\"", "[]", "{}", "2", "1.0", "tru", "True", "truee",
                       "falsey", "nul"] {
            assertFallback(flag(killed: killed))
        }
    }

    func test_killedMissing_isDropped() {
        let body = "{\"name\":\"f1\",\"trafficTypeName\":\"user\",\"status\":\"ACTIVE\",\"sets\":[]}"
        XCTAssertNil(assertSame(body))
        XCTAssertFalse(accepted(body))
    }

    func test_status_mapping_isIdenticalIncludingCase() {
        for status in ["\"ACTIVE\"", "\"active\"", "\"Active\"", "\"ARCHIVED\"", "\"archived\""] {
            assertAccepted(flag(status: status))
        }
        XCTAssertEqual(outcome(flag(status: "\"ARCHIVED\""), scanner: true)?.status, Status.archived.rawValue)
        for status in ["\"unknown\"", "\"\"", "\" active\"", "null", "1", "true", "[]", "{}", "\"ACTIV\""] {
            assertFallback(flag(status: status))
        }
        XCTAssertNil(outcome(flag(status: "\"unknown\""), scanner: true))
    }

    func test_statusMissing_isDropped() {
        let body = "{\"name\":\"f1\",\"trafficTypeName\":\"user\",\"killed\":false}"
        XCTAssertNil(assertSame(body))
    }

    func test_nameAndTrafficType_nonStringOrMissing() {
        for value in ["null", "1", "true", "[]", "{}", "[\"a\"]", "1.5"] {
            assertFallback(flag(name: value))
            assertFallback(flag(tt: value))
            XCTAssertNil(outcome(flag(name: value), scanner: true))
        }
        XCTAssertNil(assertSame("{\"trafficTypeName\":\"user\",\"status\":\"ACTIVE\",\"killed\":false}"))
        XCTAssertNil(assertSame("{\"name\":\"f1\",\"status\":\"ACTIVE\",\"killed\":false}"))
    }

    func test_emptyName_isAccepted() {
        assertAccepted(flag(name: "\"\"", tt: "\"\""))
        XCTAssertEqual(outcome(flag(name: "\"\""), scanner: true)?.name, [])
    }

    func test_numbers_inSkippedValues() {
        for number in ["0", "-0", "7", "-7", "123456789", "1.5", "-1.5", "0.0", "0.25", "10", "1e5", "1E+5", "1e-5",
                       "1.5e3", "-0e1", "123456789012345678901234567890", "1e999", "-1e999", "1e-999"] {
            let body = flag(extra: "\"n\":\(number),\"a\":[\(number),\(number)]")
            assertSame(body)
        }
        // Plain numbers, as the SDK produces them, are accepted.
        for number in ["0", "-7", "123456789", "1.5", "-0.25"] {
            assertAccepted(flag(extra: "\"n\":\(number),\"a\":[\(number),\(number)]"))
        }
    }

    func test_invalidNumbers_areDropped_inBothModes() {
        for number in ["01", "-01", "00", "-", "1.", ".5", "+1", "1e", "1e+", "--1", "1.2.3", "0x10", "NaN",
                       "Infinity", "-Infinity", "1_0", "1 2", "1a", "0.", "- 1"] {
            XCTAssertNil(assertSame(flag(extra: "\"n\":\(number)")), number)
            XCTAssertNil(assertSame(flag(extra: "\"a\":[\(number)]")), number)
            XCTAssertFalse(accepted(flag(extra: "\"n\":\(number)")), number)
        }
    }

    func test_hugeNumberThatFoundationRejects_isDroppedByBoth() {
        let huge = "1" + String(repeating: "0", count: 400)
        XCTAssertNil(assertSame(flag(extra: "\"n\":\(huge)")))
        XCTAssertNil(assertSame(flag(extra: "\"n\":-\(huge)")))
        XCTAssertNil(assertSame(flag(extra: "\"n\":1e999")))
    }

    func test_whitespace_acceptedCharacters() {
        for ws in [" ", "\t", "\n", "\r", "\r\n", " \t\r\n "] {
            let body = ws + "{" + ws + "\"name\"" + ws + ":" + ws + "\"f1\"" + ws + "," + ws
                + "\"trafficTypeName\":\"user\",\"status\":\"ACTIVE\"," + ws + "\"killed\"" + ws + ":" + ws
                + "false" + ws + "," + ws + "\"sets\"" + ws + ":" + ws + "[" + ws + "\"a\"" + ws + "," + ws
                + "\"b\"" + ws + "]" + ws + "," + ws + "\"x\"" + ws + ":" + ws + "[" + ws + "{" + ws + "}" + ws
                + "," + ws + "1" + ws + "]" + ws + "}" + ws
            assertAccepted(body)
            XCTAssertNotNil(outcome(body, scanner: true))
        }
    }

    func test_whitespace_otherCharactersAreDropped_inBothModes() {
        for ws in ["\u{0B}", "\u{0C}", "\u{A0}", "\u{2028}", "\u{0}", "\u{1}"] {
            XCTAssertNil(assertSame(ws + base), ws.debugDescription)
            XCTAssertNil(assertSame(base + ws), ws.debugDescription)
            XCTAssertNil(assertSame(base.replacingOccurrences(of: "\"killed\":", with: "\"killed\":" + ws)))
            XCTAssertFalse(accepted(base + ws))
        }
    }

    func test_degenerateBodies() {
        for body in ["", "{}", "[]", "null", "true", "false", "1", "\"a\"", "{", "}", "[", "{{}}", "{\"a\"}",
                     "{\"a\":}", "{,}", "{\"name\"}", " ", "\n", "{}{}", "[{}]", "[" + base + "]"] {
            XCTAssertNil(assertSame(body), body)
            XCTAssertFalse(accepted(body), body)
        }
    }

    func test_everyPrefixOfARealisticBody_hasTheSameOutcome() {
        let bodies = [
            "{\"name\":\"f\u{e9}\",\"trafficTypeName\":\"user\",\"status\":\"ACTIVE\",\"killed\":true,"
            + "\"sets\":[\"a\",\"b\"],\"conditions\":[{\"m\":[{\"k\":\"v\\\"}\",\"n\":-1.5}],\"p\":null}]}",
            "{\"conditions\":[],\"sets\":[],\"killed\":false,\"status\":\"archived\",\"trafficTypeName\":\"u\","
            + "\"name\":\"n\"}  \r\n"
        ]
        var prefixes = 0
        for body in bodies {
            let bytes = Array(body.utf8)
            for length in 0...bytes.count {
                assertSame(String(decoding: bytes[0..<length], as: UTF8.self))
                prefixes += 1
            }
            XCTAssertNotNil(outcome(body, scanner: true))
        }
        XCTAssertEqual(prefixes, bodies.reduce(0) { $0 + $1.utf8.count + 1 })
    }

    func test_trailingGarbage_isDropped() {
        for tail in ["x", "}", "{}", ",", "\"", "0", "[]", "\u{0}", "\u{FEFF}", "//c"] {
            XCTAssertNil(assertSame(base + tail), tail)
            XCTAssertFalse(accepted(base + tail), tail)
        }
        XCTAssertNotNil(assertSame(base + " \r\n\t "))
    }

    func test_unbalanced_isDropped() {
        for body in [String(base.dropLast()), base + "}", base.replacingOccurrences(of: "[]}", with: "[}"),
                     base.replacingOccurrences(of: "[]}", with: "]}"), "{" + base,
                     base.replacingOccurrences(of: "\"a\",\"b\"]", with: "\"a\",\"b\"}")] {
            XCTAssertNil(assertSame(body))
            XCTAssertFalse(accepted(body))
        }
    }

    func test_invalidLiterals_inSkippedValues_areDropped() {
        for literal in ["True", "TRUE", "nul", "nulll", "tru", "falsy", "undefined", "None", "'a'", "NaN"] {
            XCTAssertNil(assertSame(flag(extra: "\"x\":\(literal)")), literal)
            XCTAssertNil(assertSame(flag(extra: "\"x\":[\(literal)]")), literal)
        }
        for literal in ["true", "false", "null"] {
            assertAccepted(flag(extra: "\"x\":\(literal),\"y\":[\(literal),{\"z\":\(literal)}]"))
        }
    }

    func test_badEscapes_inSkippedStrings_areDropped() {
        for escape in ["\\x", "\\u12", "\\u12zz", "\\U0041", "\\", "\\0", "\\a", "\\'", "\\ ", "\\u"] {
            XCTAssertNil(assertSame(flag(extra: "\"x\":\"\(escape)\"")), escape)
            XCTAssertNil(assertSame(flag(extra: "\"x\":[\"\(escape)\"]")), escape)
        }
    }

    func test_controlCharactersInStrings() {
        for char in ["\u{0}", "\u{1}", "\u{8}", "\t", "\n", "\r", "\u{1F}"] {
            XCTAssertNil(assertSame(flag(name: "\"a\(char)b\"")), char.debugDescription)
            XCTAssertNil(assertSame(flag(extra: "\"x\":\"a\(char)b\"")), char.debugDescription)
            XCTAssertNil(assertSame(flag(extra: "\"a\(char)b\":1")), char.debugDescription)
            XCTAssertNil(assertSame(flag(sets: "[\"a\(char)b\"]")), char.debugDescription)
        }
    }

    func test_deleteCharacter_acceptedByFoundation_matchesInEveryField() {
        // 0x7F is accepted by JSONSerialization and kept in the string.
        for body in [flag(name: "\"a\u{7F}b\""), flag(sets: "[\"a\u{7F}\"]"), flag(extra: "\"x\":\"\u{7F}\"")] {
            assertSame(body)
            XCTAssertNotNil(outcome(body, scanner: true))
        }
    }

    func test_byteOrderMark_matchesCurrent() {
        assertFallback("\u{FEFF}" + base)
        XCTAssertNotNil(outcome("\u{FEFF}" + base, scanner: false))
        XCTAssertNil(assertSame(base + "\u{FEFF}"))
    }

    func test_leadingFEFF_inTrackedStrings_fallsBack_andMatchesCurrent() {
        let bom = "\u{FEFF}"
        assertFallback(flag(name: "\"\(bom)\""))
        assertFallback(flag(name: "\"\(bom)n\""))
        assertFallback(flag(tt: "\"\(bom)u\""))
        assertFallback(flag(status: "\"\(bom)ACTIVE\""))
        assertFallback(flag(sets: "[\"\(bom)a\"]"))
        assertFallback("{\"\(bom)name\":\"b\"," + String(base.dropFirst()))
        assertFallback("{\"\(bom)sets\":[]," + String(base.dropFirst()))
        assertFallback("{\"\(bom)killed\":true," + String(base.dropFirst()))
    }

    func test_midStringFEFF_matchesCurrent_andFallsBack() {
        let bom = "\u{FEFF}"
        assertFallback(flag(name: "\"a\(bom)b\""))
        assertFallback(flag(name: "\"ab\(bom)\""))
        assertFallback(flag(tt: "\"u\(bom)v\""))
        assertFallback(flag(sets: "[\"a\(bom)b\"]"))
        assertFallback("{\"na\(bom)me\":\"b\"," + String(base.dropFirst()))
    }

    func test_del0x7F_exactBoundary() {
        assertFallback(flag(name: "\"a\u{7F}b\""))
        assertAccepted(flag(name: "\"a\u{7E}b\""))
        assertSame(flag(extra: "\"c\":\"a\u{7F}b\""))
    }

    func test_numberLength_exactBoundary() {
        for digits in [19, 20, 21] {
            let number = "1" + String(repeating: "0", count: digits - 1)
            assertSame(flag(extra: "\"n\":\(number)"))
            assertSame(flag(extra: "\"n\":-\(number)"))
            assertSame(flag(extra: "\"n\":[\(number)]"))
        }
        assertAccepted(flag(extra: "\"n\":" + "1" + String(repeating: "0", count: 19)))
        assertFallback(flag(extra: "\"n\":" + "1" + String(repeating: "0", count: 20)))
    }

    func test_trailingCommas_foundationAcceptsThem_scannerFallsBack() {
        let bodies = [String(base.dropLast()) + ",}", flag(sets: "[\"a\",\"b\",]"), flag(extra: "\"x\":[1,2,]"),
                      flag(extra: "\"x\":{\"a\":1,}")]
        for body in bodies {
            XCTAssertNotNil(outcome(body, scanner: false), body)
            assertFallback(body)
        }
        for body in [String(base.dropLast()) + ",,}", "{," + base.dropFirst(), flag(extra: "\"x\":[,1]"),
                     flag(extra: "\"x\":[1,,2]")] {
            XCTAssertNil(assertSame(body))
        }
    }

    func test_depth_nestedArraysAndObjects_doNotCrash_andMatch() {
        for depth in [1, 50, 100, 127, 128, 129, 200, 255, 256, 257, 400, 511, 512, 513, 514, 600, 10_000, 50_000] {
            let arrays = flag(extra: "\"x\":" + String(repeating: "[", count: depth)
                + String(repeating: "]", count: depth))
            assertSame(arrays)
            let objects = flag(extra: String(repeating: "\"x\":{", count: depth) + "1"
                + String(repeating: "}", count: depth))
            assertSame(objects)
            let unclosed = flag(extra: "\"x\":" + String(repeating: "[", count: depth))
            assertSame(unclosed)
        }
        XCTAssertNil(outcome(flag(extra: "\"x\":" + String(repeating: "[", count: 10_000)
            + String(repeating: "]", count: 10_000)), scanner: true))
        assertAccepted(flag(extra: "\"x\":" + String(repeating: "[", count: 20) + String(repeating: "]", count: 20)))
    }

    // MARK: - JSONSerialization quirks the scanner relies on (each one verified by running it)

    private func foundationAccepts(_ body: String) -> Bool {
        (try? JSONSerialization.jsonObject(with: Data(body.utf8), options: [])) != nil
    }

    func test_quirk_JSONSerialization_acceptsTrailingCommas() {
        XCTAssertTrue(foundationAccepts("{\"a\":1,}"))
        XCTAssertTrue(foundationAccepts("{\"a\":[1,]}"))
        XCTAssertFalse(foundationAccepts("{\"a\":[1,,]}"))
        XCTAssertFalse(foundationAccepts("{,\"a\":1}"))
    }

    func test_quirk_JSONSerialization_numberRules() {
        XCTAssertFalse(foundationAccepts("{\"a\":01}"))
        XCTAssertFalse(foundationAccepts("{\"a\":NaN}"))
        XCTAssertFalse(foundationAccepts("{\"a\":1e999}"))
        XCTAssertTrue(foundationAccepts("{\"a\":-1e999}"))
        XCTAssertTrue(foundationAccepts("{\"a\":-0}"))
        XCTAssertTrue(foundationAccepts("{\"a\":123456789012345678901234567890}"))
        XCTAssertFalse(foundationAccepts("{\"a\":1" + String(repeating: "0", count: 400) + "}"))
    }

    func test_quirk_JSONSerialization_topLevelMustBeAContainer() {
        XCTAssertFalse(foundationAccepts("\"a\""))
        XCTAssertFalse(foundationAccepts("1"))
        XCTAssertFalse(foundationAccepts("null"))
        XCTAssertFalse(foundationAccepts(""))
        XCTAssertTrue(foundationAccepts("[]"))
        XCTAssertTrue(foundationAccepts("\u{FEFF}{}"))
    }

    func test_quirk_JSONSerialization_duplicateKeysLastWins() throws {
        let object = try XCTUnwrap(try JSONSerialization.jsonObject(
            with: Data("{\"a\":1,\"a\":2}".utf8), options: []) as? [String: Any])
        XCTAssertEqual(object["a"] as? Int, 1)
    }

    func test_quirk_JSONSerialization_stringRules() {
        XCTAssertTrue(foundationAccepts("{\"a\":\"\\u0000\"}"))
        XCTAssertFalse(foundationAccepts("{\"a\":\"\\ud800\"}"))
        XCTAssertFalse(foundationAccepts("{\"a\":\"\\udc00x\"}"))
        XCTAssertTrue(foundationAccepts("{\"a\":\"\\ud83d\\ude00\"}"))
        XCTAssertFalse(foundationAccepts("{\"a\":\"x\ty\"}"))
        XCTAssertFalse(foundationAccepts("{\"a\":\"x\ny\"}"))
        XCTAssertTrue(foundationAccepts("{\"a\":\"x\u{7F}y\"}"))
    }

    func test_quirk_JSONSerialization_whitespaceAndDepth() {
        XCTAssertTrue(foundationAccepts("\t\r\n {}"))
        XCTAssertFalse(foundationAccepts("\u{0B}{}"))
        XCTAssertFalse(foundationAccepts("\u{0C}{}"))
        XCTAssertFalse(foundationAccepts("\u{A0}{}"))
        XCTAssertFalse(foundationAccepts("{}x"))
        let nested = { (n: Int) in "{\"a\":" + String(repeating: "[", count: n) + String(repeating: "]", count: n) + "}" }
        XCTAssertTrue(foundationAccepts(nested(512)))
        XCTAssertFalse(foundationAccepts(nested(513)))
    }

    // MARK: - 3. Seeded fuzz

    private static let fuzzSeed: UInt64 = 54_007

    private func realisticSeeds() throws -> [String] {
        var seeds = Array(try fixtureBodies(size: .small).prefix(25))
        seeds.append(base)
        seeds.append(flag(name: "\"ñandú😀\"", sets: "[\"sé\"]", extra:
            "\"conditions\":[{\"m\":[{\"k\":\"v\\\"}\",\"n\":-1.5e3}],\"p\":null,\"q\":\"\\ud83d\\ude00\"}]"))
        seeds.append("{\"conditions\":[{\"name\":\"x\",\"killed\":true}],\"sets\":[],\"killed\":true,"
            + "\"status\":\"archived\",\"trafficTypeName\":\"u\",\"name\":\"n\"}")
        seeds.append("  {\t\"name\" : \"n\" ,\r\n\"trafficTypeName\":\"u\",\"status\":\"ACTIVE\",\"killed\":false}\n")
        return seeds
    }

    private static let mutationAlphabet: [UInt8] = Array("\"\\{}[],: \u{0}\u{1}\t\n\u{7F}e-0u1tfn.+".utf8)

    private func mutate(_ body: String, _ rng: inout SplitMix64) -> String {
        var bytes = Array(body.utf8)
        let steps = 1 + rng.nextInt(3)
        for _ in 0..<steps where !bytes.isEmpty {
            // Half of the edits land in the first 200 bytes, where the tracked keys live.
            let span = rng.nextInt(2) == 0 ? min(bytes.count, 200) : bytes.count
            let at = rng.nextInt(span)
            let symbol = Self.mutationAlphabet[rng.nextInt(Self.mutationAlphabet.count)]
            switch rng.nextInt(8) {
            case 0:
                bytes.remove(at: at)
            case 1:
                bytes.insert(symbol, at: at)
            case 2:
                bytes[at] = symbol
            case 3:
                bytes.insert(bytes[at], at: at)
            case 7:
                bytes.insert(contentsOf: [0xEF, 0xBB, 0xBF], at: at)
            case 4:
                bytes.removeSubrange(at..<min(bytes.count, at + 1 + rng.nextInt(8)))
            case 5:
                let end = min(bytes.count, at + 1 + rng.nextInt(12))
                bytes.insert(contentsOf: bytes[at..<end], at: rng.nextInt(bytes.count))
            default:
                bytes.removeSubrange(at..<bytes.count)
            }
        }
        return String(decoding: bytes, as: UTF8.self)
    }

    private func randomString(_ rng: inout SplitMix64) -> String {
        let plain = ["a", "\u{FEFF}", "\u{FEFF}name", "f1", "user", "ACTIVE", "archived", "", "é", "😀", "x y", "}", "{", "]", "[", ",", ":"]
        let escaped = ["\\\"", "\\\\", "\\n", "\\u0041", "\\ud83d\\ude00", "\\ud83d", "\\/", "\u{7F}", "\\x"]
        var text = ""
        for _ in 0..<rng.nextInt(4) {
            text += rng.nextInt(6) == 0 ? escaped[rng.nextInt(escaped.count)] : plain[rng.nextInt(plain.count)]
        }
        return "\"" + text + "\""
    }

    private func randomWhitespace(_ rng: inout SplitMix64) -> String {
        if rng.nextInt(60) == 0 {
            return "\u{0B}"
        }
        let options = ["", "", "", " ", "\n", "\t", "\r\n"]
        return options[rng.nextInt(options.count)]
    }

    private func randomValue(_ rng: inout SplitMix64, depth: Int) -> String {
        let valid = ["true", "false", "null", "0", "-1", "12.5", "1e5"]
        let invalid = ["01", "1.", "tru", "NaN", "-"]
        let leaves = rng.nextInt(12) == 0 ? invalid : valid
        let choice = rng.nextInt(depth > 3 ? 3 : 6)
        switch choice {
        case 0:
            return randomString(&rng)
        case 1:
            return leaves[rng.nextInt(leaves.count)]
        case 2:
            return randomString(&rng)
        case 3:
            let count = rng.nextInt(4)
            let items = (0..<count).map { _ in randomWhitespace(&rng) + randomValue(&rng, depth: depth + 1)
                + randomWhitespace(&rng) }
            return "[" + items.joined(separator: ",") + (rng.nextInt(12) == 0 ? "," : "") + "]"
        default:
            let count = rng.nextInt(4)
            let keys = ["name", "killed", "status", "sets", "x", "trafficTypeName", "k\\u0031"]
            let items = (0..<count).map { _ in "\"" + keys[rng.nextInt(keys.count)] + "\":"
                + randomValue(&rng, depth: depth + 1) }
            return "{" + items.joined(separator: ",") + "}"
        }
    }

    private func randomDocument(_ rng: inout SplitMix64) -> String {
        var members = [String]()
        let names = ["\"f1\"", "\"é\"", "\"\"", "null", "1", "\"a\\\"b\"", "\"x\\u00e9\"", "[\"a\"]"]
        let types = ["\"user\"", "\"u\"", "null", "2", "\"t\\u0031\""]
        let statuses = ["\"ACTIVE\"", "\"archived\"", "\"Active\"", "\"nope\"", "null", "true"]
        let killeds = ["true", "false", "false", "false", "0", "1", "null", "\"true\""]
        let sets = ["[\"a\",\"b\"]", "[]", "null", "[1]", "[\"a\",1]", "\"a\"", "[\"a\",\"a\"]", "[\"é\"]", "{}",
                    "[\"a\",]"]
        func maybe(_ key: String, _ options: [String]) {
            // Absent about one time in ten, duplicated about one time in twelve.
            if rng.nextInt(16) == 0 {
                return
            }
            // The first option is the common valid value; the rest are the unusual ones.
            let pick = rng.nextInt(3) == 0 ? rng.nextInt(options.count) : 0
            members.append("\"\(key)\"" + randomWhitespace(&rng) + ":" + randomWhitespace(&rng)
                + options[pick])
            if rng.nextInt(24) == 0 {
                members.append("\"\(key)\":" + options[rng.nextInt(options.count)])
            }
        }
        maybe("name", names)
        maybe("trafficTypeName", types)
        maybe("status", statuses)
        maybe("killed", killeds)
        maybe("sets", sets)
        for _ in 0..<rng.nextInt(3) {
            members.append(randomString(&rng) + ":" + randomValue(&rng, depth: 0))
        }
        // Fisher-Yates shuffle with the seeded generator.
        if members.count > 1 {
            for index in stride(from: members.count - 1, to: 0, by: -1) {
                members.swapAt(index, rng.nextInt(index + 1))
            }
        }
        var text = randomWhitespace(&rng) + "{" + members.joined(separator: ",")
            + (rng.nextInt(15) == 0 ? "," : "") + "}" + randomWhitespace(&rng)
        if rng.nextInt(8) == 0 {
            text = mutate(text, &rng)
        }
        return text
    }

    private func runFuzz(cases: Int, seed: UInt64, label: String, makeBody: (inout SplitMix64) -> String) {
        var rng = SplitMix64(seed: seed)
        var failures = [String]()
        var acceptedCount = 0
        var droppedCount = 0
        for index in 0..<cases {
            let body = makeBody(&rng)
            let current = outcome(body, scanner: false)
            let scanner = outcome(body, scanner: true)
            if current != scanner {
                failures.append("seed \(seed) case \(index): \(describe(body))")
            }
            if accepted(body) {
                acceptedCount += 1
            }
            if current == nil {
                droppedCount += 1
            }
        }
        XCTAssertEqual(failures.prefix(10).joined(separator: "\n"), "", "\(label): \(failures.count) mismatches, accepted \(acceptedCount), dropped \(droppedCount)")
        // The fuzz must reach every path: scanner accepts, falls back with a result, and drops.
        XCTAssertGreaterThan(acceptedCount, cases / 20, "\(label): scanner path rarely taken")
        XCTAssertGreaterThan(droppedCount, cases / 20, "\(label): too few dropped bodies")
        XCTAssertGreaterThan(cases - droppedCount - acceptedCount, 20,
                             "\(label): too few fallback-with-result bodies")
    }

    func test_fuzz_mutatedRealisticBodies_outcomesMatch() throws {
        let seeds = try realisticSeeds()
        runFuzz(cases: 12_000, seed: Self.fuzzSeed, label: "mutation fuzz") { rng in
            self.mutate(seeds[rng.nextInt(seeds.count)], &rng)
        }
    }

    func test_fuzz_randomJsonishDocuments_outcomesMatch() {
        runFuzz(cases: 12_000, seed: Self.fuzzSeed &+ 1, label: "document fuzz") { rng in
            self.randomDocument(&rng)
        }
    }

    // MARK: - 4. Decoder level

    private struct PrefixCipher: Cipher {
        func encrypt(_ text: String?) -> String? {
            text.map { "ENC:" + $0 }
        }

        func decrypt(_ text: String?) -> String? {
            guard let text = text, text.hasPrefix("ENC:") else {
                return nil
            }
            return String(text.dropFirst(4))
        }
    }

    func test_decode_dropsTheSameElements_inBothModes_withAndWithoutCipher() {
        let good1 = flag(name: "\"g1\"")
        let good2 = flag(name: "\"g2\"", sets: nil)
        let escaped = flag(name: "\"e\\u0041\"")
        let list = ["ENC:" + good1, "ENC:{bad", good2, "garbage", "ENC:" + escaped, "ENC:" + good2,
                    "ENC:" + String(good1.dropLast()), "ENC:" + flag(status: "\"nope\""), ""]
        for cipher: Cipher? in [PrefixCipher(), nil] {
            let current = referenceDecode(list, cipher: cipher)
            let scanner = SplitsSerialDecoder(cipher: cipher).decode(list).map(snapshot)
            XCTAssertEqual(current, scanner)
            XCTAssertEqual(current.count, cipher == nil ? 1 : 4)
        }
        XCTAssertEqual(SplitsSerialDecoder(cipher: nil).decode([]).count, 0)
    }

    func test_parallelDecoder_returnsTheSameSplitsAsTheReference() throws {
        let bodies = Array(try fixtureBodies(size: .small).prefix(120))
        let actual = SplitsParallelDecoder(minTaskPerThread: 10, timeChecker: TimeChecker.forTesting()).decode(bodies)
        func sorted(_ splits: [Snapshot]) -> [Snapshot] {
            splits.sorted { ($0.name ?? []).lexicographicallyPrecedes($1.name ?? []) }
        }
        let reference = referenceDecode(bodies, cipher: nil)
        XCTAssertEqual(actual.count, 120)
        XCTAssertEqual(sorted(actual.map(snapshot)), sorted(reference))
    }

    func test_malformedUtf8Bytes_cannotReachEitherPath_andBothPathsAgree() {
        let malformed: [[UInt8]] = [[0x80], [0xC0, 0xAF], [0xED, 0xA0, 0x80], [0xE2, 0x82], [0xF8], [0xFF], [0xF4, 0x90, 0x80, 0x80]]
        for bytes in malformed {
            // Foundation refuses the raw bytes, so a String built that way is nil and never decoded.
            XCTAssertNil(String(bytes: bytes, encoding: .utf8), "\(bytes)")
            XCTAssertNil(NSString(bytes: bytes, length: bytes.count, encoding: String.Encoding.utf8.rawValue), "\(bytes)")
            let lossy = String(decoding: bytes, as: UTF8.self)
            XCTAssertTrue(lossy.unicodeScalars.contains("\u{FFFD}"), "\(bytes)")
            XCTAssertNotNil(lossy.data(using: .utf8))
            for (inName, inSkipped) in [(true, false), (false, true)] {
                var raw = Array("{\"name\":\"".utf8)
                raw += inName ? bytes : Array("f1".utf8)
                raw += Array("\",\"trafficTypeName\":\"user\",\"status\":\"ACTIVE\",\"killed\":false,\"x\":\"".utf8)
                raw += inSkipped ? bytes : Array("y".utf8)
                raw += Array("\",\"conditions\":[]}".utf8)
                let body = String(decoding: raw, as: UTF8.self)
                XCTAssertEqual(Array(body.utf8).contains(0xFF), false)
                let result = assertSame(body)
                XCTAssertNotNil(result, "\(bytes)")
                if inName {
                    XCTAssertTrue(String(decoding: result!.name!, as: UTF8.self).contains("\u{FFFD}"))
                }
                XCTAssertEqual(SplitsSerialDecoder(cipher: nil).decode([body]).count, 1)
            }
        }
    }
}
