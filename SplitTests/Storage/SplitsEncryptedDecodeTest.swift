//
//  SplitsEncryptedDecodeTest.swift
//  SplitTests
//
//  Scanner path vs JSONSerialization reference when storage encryption is on.
//

import Foundation
import XCTest
@testable import Split

class SplitsEncryptedDecodeTest: XCTestCase {

    private let cipher = DefaultCipher(cipherKey: "0123456789abcdef".dataBytes!)
    private let otherCipher = DefaultCipher(cipherKey: "fedcba9876543210".dataBytes!)

    private func flag(name: String, extra: String = "") -> String {
        "{\"trafficTypeName\":\"user\",\"name\":\(name),\"status\":\"ACTIVE\",\"killed\":false,\"sets\":[\"a\",\"b\"]\(extra)}"
    }

    /// Mix of bodies the scanner accepts and bodies it falls back on.
    private var plainBodies: [String] {
        [
            flag(name: "\"plain\""),
            flag(name: "\"esc\\u0041\\n\\\"q\\\"\""),
            "{\"name\":\"dup1\",\"name\":\"dup2\",\"trafficTypeName\":\"user\",\"status\":\"ACTIVE\",\"killed\":true}",
            flag(name: "\"na\u{00EF}ve_\u{65E5}\u{672C}_\u{1F600}\""),
            flag(name: "\"conf\"", extra: ",\"configurations\":{\"on\":\"{\\\"k\\\":1}\"},\"conditions\":[]")
        ]
    }

    private struct Snap: Equatable {
        let name: String?, trafficType: String?, status: Int?, sets: Set<String>?, killed: Bool?, json: String
    }

    private func snap(_ s: Split) -> Snap {
        Snap(name: s.name, trafficType: s.trafficTypeName, status: s.status?.rawValue,
             sets: s.sets, killed: s.killed, json: s.json)
    }

    private func reference(_ plain: [String]) -> [Snap] {
        let d = SplitsSerialDecoder(cipher: nil)
        return plain.compactMap { try? d.getSplitUsingJSONSerialization($0) }.map(snap)
    }

    private func parallel(_ c: Cipher?) -> SplitsParallelDecoder {
        // minTaskPerThread 1 forces more than one task on multi-core hosts
        SplitsParallelDecoder(minTaskPerThread: 1, cipher: c, timeChecker: TimeChecker.forTesting())
    }

    private func sortedByName(_ s: [Snap]) -> [Snap] { s.sorted { ($0.name ?? "") < ($1.name ?? "") } }

    func test_encryptedBodies_decodeLikeReference_serialAndParallel() {
        let plain = plainBodies
        let encrypted = plain.map { cipher.encrypt($0)! }
        XCTAssertEqual(Set(encrypted).count, plain.count)
        for (p, e) in zip(plain, encrypted) { XCTAssertNotEqual(p, e) }

        let expected = reference(plain)
        XCTAssertEqual(expected.count, plain.count)

        let serial = SplitsSerialDecoder(cipher: cipher).decode(encrypted).map(snap)
        XCTAssertEqual(serial, expected)
        for (s, p) in zip(serial, plain) { XCTAssertEqual(s.json, p) }

        let par = parallel(cipher).decode(encrypted).map(snap)
        XCTAssertEqual(sortedByName(par), sortedByName(expected))
        XCTAssertEqual(Set(par.map { $0.json }), Set(plain))
    }

    func test_fixtures_coverBothScannerAndFallbackPaths() {
        let accepted = plainBodies.filter {
            if case .fields = SplitsTopLevelScanner.scan($0) { return true }
            return false
        }
        XCTAssertGreaterThan(accepted.count, 0)
        XCTAssertLessThan(accepted.count, plainBodies.count)
    }

    func test_invalidCiphertext_isDropped() {
        let good = cipher.encrypt(plainBodies[0])!
        XCTAssertEqual(SplitsSerialDecoder(cipher: cipher).decode(["not-ciphertext!!", "", "AAAA"]).count, 0)
        XCTAssertEqual(SplitsSerialDecoder(cipher: cipher).decode(["not-ciphertext!!", good]).count, 1)
        XCTAssertEqual(parallel(cipher).decode(["not-ciphertext!!", "AAAA"]).count, 0)
    }

    func test_wrongKeyCiphertext_isDropped() {
        let wrong = plainBodies.map { otherCipher.encrypt($0)! }
        XCTAssertEqual(SplitsSerialDecoder(cipher: cipher).decode(wrong).count, 0)
        XCTAssertEqual(parallel(cipher).decode(wrong).count, 0)
    }

    /// Current behavior: decrypt returns nil for plaintext JSON (not valid base64 ciphertext), so
    /// `cipher?.decrypt(json) ?? json` falls back to the raw string and the plaintext body IS decoded.
    func test_plaintextBodyGivenToDecoderWithCipher_currentBehavior() {
        let plain = plainBodies
        let decrypted = plain.map { cipher.decrypt($0) }
        let result = SplitsSerialDecoder(cipher: cipher).decode(plain).map(snap)
        if decrypted.allSatisfy({ $0 == nil }) {
            // decrypt failed -> falls back to the raw string -> decoded as plaintext
            XCTAssertEqual(result, reference(plain))
        } else {
            XCTFail("unexpected: some plaintext bodies decrypted to something: \(decrypted)")
        }
    }

    func test_mixedList_keepsValidOnesInOrder() {
        let plain = plainBodies
        let list = [cipher.encrypt(plain[1])!, "garbage", otherCipher.encrypt(plain[0])!, cipher.encrypt(plain[2])!]
        let expected = reference([plain[1], plain[2]])
        XCTAssertEqual(expected.count, 2)
        let serial = SplitsSerialDecoder(cipher: cipher).decode(list).map(snap)
        XCTAssertEqual(serial, expected)
        // the parallel decoder appends chunk results in completion order, so only the serial path guarantees order
        XCTAssertEqual(sortedByName(parallel(cipher).decode(list).map(snap)), sortedByName(expected))
    }
}
