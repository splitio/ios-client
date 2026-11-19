//
//  SplitsTopLevelScanner.swift
//  Split
//

import Foundation

/// The five top-level fields `SplitsSerialDecoder.getSplit` reads from a flag body.
struct ScannedSplitFields {
    let name: String
    let trafficType: String
    let status: Status
    let sets: Set<String>?
    let killed: Bool
}

enum SplitsTopLevelScan {
    case fields(ScannedSplitFields)
    /// The scanner is not sure: the caller must run the JSONSerialization path.
    case fallback
}

/// Reads name, trafficTypeName, status, sets and killed from the top level of a flag body in one
/// pass over its UTF-8 bytes, skipping every other value without building a tree.
///
/// Exactness rule: the scanner only accepts a body that it has verified completely against strict
/// JSON, in which each tracked key appears once, unescaped, with a plain value. Anything else
/// (escapes in the values it reads or in any key, duplicate keys, BOM, trailing commas, exponents,
/// long numbers, deep nesting, wrong types, missing keys, malformed text) returns `.fallback` and the
/// caller runs JSONSerialization, which then decides. The scanner never drops a body itself.
enum SplitsTopLevelScanner {

    /// Nesting beyond this falls back. JSONSerialization rejects about 512 levels; staying far below
    /// keeps the recursion shallow and leaves that boundary entirely to JSONSerialization.
    private static let maxDepth = 100
    /// JSONSerialization rejects numbers that overflow (400 digits); a long token falls back.
    private static let maxNumberLength = 20

    static func scan(_ json: String) -> SplitsTopLevelScan {
        var text = json
        let result: SplitsTopLevelScan? = text.withUTF8 { bytes in
            var scanner = Cursor(bytes: bytes)
            return scanner.scanTopLevel()
        }
        return result ?? .fallback
    }

    private struct Cursor {
        let bytes: UnsafeBufferPointer<UInt8>
        let count: Int
        var index = 0

        init(bytes: UnsafeBufferPointer<UInt8>) {
            self.bytes = bytes
            self.count = bytes.count
        }

        // MARK: Top level

        mutating func scanTopLevel() -> SplitsTopLevelScan? {
            skipWhitespace()
            guard consume(UInt8(ascii: "{")) else {
                return nil
            }
            var name: Range<Int>?
            var trafficType: Range<Int>?
            var status: Range<Int>?
            var killed: Bool?
            var setsSeen = false
            var sets: [Range<Int>]?

            skipWhitespace()
            if peek() == UInt8(ascii: "}") {
                return nil
            }
            while true {
                skipWhitespace()
                guard let key = scanPlainString() else {
                    return nil
                }
                skipWhitespace()
                guard consume(UInt8(ascii: ":")) else {
                    return nil
                }
                skipWhitespace()
                switch keyKind(key) {
                case .name:
                    guard name == nil, let range = scanPlainString() else {
                        return nil
                    }
                    name = range
                case .trafficTypeName:
                    guard trafficType == nil, let range = scanPlainString() else {
                        return nil
                    }
                    trafficType = range
                case .status:
                    guard status == nil, let range = scanPlainString() else {
                        return nil
                    }
                    status = range
                case .killed:
                    guard killed == nil, let value = scanBoolean() else {
                        return nil
                    }
                    killed = value
                case .sets:
                    guard !setsSeen else {
                        return nil
                    }
                    setsSeen = true
                    if matchLiteral("null") {
                        sets = nil
                    } else if let list = scanStringArray() {
                        sets = list
                    } else {
                        return nil
                    }
                case .other:
                    guard skipValue(depth: 1) else {
                        return nil
                    }
                }
                skipWhitespace()
                guard let next = peek() else {
                    return nil
                }
                index += 1
                if next == UInt8(ascii: ",") {
                    continue
                }
                if next == UInt8(ascii: "}") {
                    break
                }
                return nil
            }
            skipWhitespace()
            guard index == count,
                  let nameRange = name, let trafficRange = trafficType, let statusRange = status,
                  let killedValue = killed,
                  let statusValue = Status.enumFromString(string: string(statusRange)) else {
                return nil
            }
            return .fields(ScannedSplitFields(name: string(nameRange), trafficType: string(trafficRange),
                                              status: statusValue,
                                              sets: sets.map { Set($0.map { string($0) }) },
                                              killed: killedValue))
        }

        // MARK: Keys

        private enum KeyKind {
            case name, trafficTypeName, status, killed, sets, other
        }

        private func keyKind(_ range: Range<Int>) -> KeyKind {
            switch range.count {
            case 4:
                if equals(range, "name") {
                    return .name
                }
                return equals(range, "sets") ? .sets : .other
            case 6:
                if equals(range, "status") {
                    return .status
                }
                return equals(range, "killed") ? .killed : .other
            case 15:
                return equals(range, "trafficTypeName") ? .trafficTypeName : .other
            default:
                return .other
            }
        }

        private func equals(_ range: Range<Int>, _ literal: StaticString) -> Bool {
            let length = literal.utf8CodeUnitCount
            guard range.count == length else {
                return false
            }
            let expected = literal.utf8Start
            for offset in 0..<length where bytes[range.lowerBound + offset] != expected[offset] {
                return false
            }
            return true
        }

        private func string(_ range: Range<Int>) -> String {
            String(decoding: UnsafeBufferPointer(rebasing: bytes[range]), as: UTF8.self)
        }

        // MARK: Tracked values

        /// A string with no escape, no control character and no DEL: its bytes are its value.
        private mutating func scanPlainString() -> Range<Int>? {
            guard consume(UInt8(ascii: "\"")) else {
                return nil
            }
            let start = index
            while index < count {
                let byte = bytes[index]
                if byte == UInt8(ascii: "\"") {
                    let range = start..<index
                    index += 1
                    return range
                }
                if byte < 0x20 || byte == UInt8(ascii: "\\") || byte == 0x7F {
                    return nil
                }
                // Foundation drops a leading U+FEFF (EF BB BF) from string content: fall back on it anywhere.
                if byte == 0xEF, index + 2 < count, bytes[index + 1] == 0xBB, bytes[index + 2] == 0xBF {
                    return nil
                }
                index += 1
            }
            return nil
        }

        private mutating func scanBoolean() -> Bool? {
            if matchLiteral("true") {
                return true
            }
            if matchLiteral("false") {
                return false
            }
            return nil
        }

        /// A flat array of plain strings. Anything else (non-strings, nesting, trailing comma) is nil.
        private mutating func scanStringArray() -> [Range<Int>]? {
            guard consume(UInt8(ascii: "[")) else {
                return nil
            }
            var items = [Range<Int>]()
            skipWhitespace()
            if consume(UInt8(ascii: "]")) {
                return items
            }
            while true {
                skipWhitespace()
                guard let item = scanPlainString() else {
                    return nil
                }
                items.append(item)
                skipWhitespace()
                guard let next = peek() else {
                    return nil
                }
                index += 1
                if next == UInt8(ascii: ",") {
                    continue
                }
                return next == UInt8(ascii: "]") ? items : nil
            }
        }

        // MARK: Skipped values

        /// Skips one JSON value, validating it against strict JSON. `depth` is the nesting of the value.
        private mutating func skipValue(depth: Int) -> Bool {
            guard let byte = peek() else {
                return false
            }
            switch byte {
            case UInt8(ascii: "\""):
                return skipString()
            case UInt8(ascii: "{"):
                return skipObject(depth: depth)
            case UInt8(ascii: "["):
                return skipArray(depth: depth)
            case UInt8(ascii: "t"):
                return matchLiteral("true")
            case UInt8(ascii: "f"):
                return matchLiteral("false")
            case UInt8(ascii: "n"):
                return matchLiteral("null")
            default:
                return skipNumber()
            }
        }

        private mutating func skipObject(depth: Int) -> Bool {
            guard depth < SplitsTopLevelScanner.maxDepth else {
                return false
            }
            index += 1
            skipWhitespace()
            if consume(UInt8(ascii: "}")) {
                return true
            }
            while true {
                skipWhitespace()
                guard skipString() else {
                    return false
                }
                skipWhitespace()
                guard consume(UInt8(ascii: ":")) else {
                    return false
                }
                skipWhitespace()
                guard skipValue(depth: depth + 1) else {
                    return false
                }
                skipWhitespace()
                guard let next = peek() else {
                    return false
                }
                index += 1
                if next == UInt8(ascii: ",") {
                    continue
                }
                return next == UInt8(ascii: "}")
            }
        }

        private mutating func skipArray(depth: Int) -> Bool {
            guard depth < SplitsTopLevelScanner.maxDepth else {
                return false
            }
            index += 1
            skipWhitespace()
            if consume(UInt8(ascii: "]")) {
                return true
            }
            while true {
                skipWhitespace()
                guard skipValue(depth: depth + 1) else {
                    return false
                }
                skipWhitespace()
                guard let next = peek() else {
                    return false
                }
                index += 1
                if next == UInt8(ascii: ",") {
                    continue
                }
                return next == UInt8(ascii: "]")
            }
        }

        /// Skips a string, validating escapes. A lone surrogate escape is rejected like JSONSerialization does.
        private mutating func skipString() -> Bool {
            guard consume(UInt8(ascii: "\"")) else {
                return false
            }
            while index < count {
                let byte = bytes[index]
                if byte == UInt8(ascii: "\"") {
                    index += 1
                    return true
                }
                if byte < 0x20 {
                    return false
                }
                if byte != UInt8(ascii: "\\") {
                    index += 1
                    continue
                }
                guard index + 1 < count else {
                    return false
                }
                switch bytes[index + 1] {
                case UInt8(ascii: "\""), UInt8(ascii: "\\"), UInt8(ascii: "/"), UInt8(ascii: "b"),
                     UInt8(ascii: "f"), UInt8(ascii: "n"), UInt8(ascii: "r"), UInt8(ascii: "t"):
                    index += 2
                case UInt8(ascii: "u"):
                    guard let unit = hex4(at: index + 2) else {
                        return false
                    }
                    if unit >= 0xD800 && unit <= 0xDBFF {
                        guard index + 11 < count, bytes[index + 6] == UInt8(ascii: "\\"),
                              bytes[index + 7] == UInt8(ascii: "u"),
                              let low = hex4(at: index + 8), low >= 0xDC00 && low <= 0xDFFF else {
                            return false
                        }
                        index += 12
                    } else if unit >= 0xDC00 && unit <= 0xDFFF {
                        return false
                    } else {
                        index += 6
                    }
                default:
                    return false
                }
            }
            return false
        }

        private func hex4(at start: Int) -> UInt32? {
            guard start + 3 < count else {
                return nil
            }
            var value: UInt32 = 0
            for offset in 0..<4 {
                let byte = bytes[start + offset]
                let digit: UInt32
                switch byte {
                case UInt8(ascii: "0")...UInt8(ascii: "9"):
                    digit = UInt32(byte - UInt8(ascii: "0"))
                case UInt8(ascii: "a")...UInt8(ascii: "f"):
                    digit = UInt32(byte - UInt8(ascii: "a")) + 10
                case UInt8(ascii: "A")...UInt8(ascii: "F"):
                    digit = UInt32(byte - UInt8(ascii: "A")) + 10
                default:
                    return nil
                }
                value = value << 4 | digit
            }
            return value
        }

        /// `-?(0|[1-9][0-9]*)(\.[0-9]+)?`. No exponent (falls back) and a length cap.
        private mutating func skipNumber() -> Bool {
            let start = index
            _ = consume(UInt8(ascii: "-"))
            guard let first = peek(), isDigit(first) else {
                return false
            }
            index += 1
            if first != UInt8(ascii: "0") {
                while let byte = peek(), isDigit(byte) {
                    index += 1
                }
            }
            if consume(UInt8(ascii: ".")) {
                guard let byte = peek(), isDigit(byte) else {
                    return false
                }
                while let byte = peek(), isDigit(byte) {
                    index += 1
                }
            }
            return index - start <= SplitsTopLevelScanner.maxNumberLength
        }

        // MARK: Primitives

        @inline(__always)
        private func isDigit(_ byte: UInt8) -> Bool {
            byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9")
        }

        @inline(__always)
        private func peek() -> UInt8? {
            index < count ? bytes[index] : nil
        }

        @inline(__always)
        private mutating func consume(_ byte: UInt8) -> Bool {
            if index < count && bytes[index] == byte {
                index += 1
                return true
            }
            return false
        }

        /// Whitespace as JSONSerialization takes it: space, tab, line feed, carriage return.
        @inline(__always)
        private mutating func skipWhitespace() {
            while index < count {
                let byte = bytes[index]
                if byte == 0x20 || byte == 0x0A || byte == 0x0D || byte == 0x09 {
                    index += 1
                } else {
                    return
                }
            }
        }

        private mutating func matchLiteral(_ literal: StaticString) -> Bool {
            let length = literal.utf8CodeUnitCount
            guard index + length <= count else {
                return false
            }
            let expected = literal.utf8Start
            for offset in 0..<length where bytes[index + offset] != expected[offset] {
                return false
            }
            index += length
            return true
        }
    }
}
