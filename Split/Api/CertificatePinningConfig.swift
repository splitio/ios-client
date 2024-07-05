//
//  CertificatePinningConfig.swift
//  Split
//
//  Created by Javier L. Avrudsky on 04/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@objc
public class CertificatePinningError: NSObject, LocalizedError {
    private let message: String

    init(message: String) {
        self.message = message
    }

    public var errorDescription: String? {
        return message
    }
}

@objc public class CertificatePinningConfig: NSObject {
    private (set) var pins: [CredentialPin]

    init(pins: [CredentialPin]) {
        self.pins = pins
    }

    @objc(builder)
    public static func builder() -> Builder {
        return Builder()
    }

    @objc(CertificatePinningConfigBuilder)
    public class Builder: NSObject {
        private struct HashField {
            static let algo = 0
            static let key = 1
            private init() {}
        }

        private enum PinType {
            case key
            case certificate
        }

        private struct Pin {
            let host: String
            let data: String
            let type: PinType
        }

        private let splitValidator = SplitNameValidator()
        private var builderPins = [Pin]()

        // Visible for testing variable
        var bundle: Bundle = Bundle.main

        @objc
        public func build() throws -> CertificatePinningConfig {
            var pins = [CredentialPin]()
            for pin in builderPins {
                let credential = (pin.type == .certificate ? try parseCertificate(pin: pin) : try parseHash(pin: pin))
                pins.append(credential)
            }
            return CertificatePinningConfig(pins: pins)
        }

        @discardableResult
        @objc(addPinForHost:certificateName:)
        public func addPin(host: String, certificateName: String) -> CertificatePinningConfig.Builder {
            builderPins.append(Pin(host: host, data: certificateName, type: .certificate))
            return self
        }

        @discardableResult
        @objc(addPinForHost:hash:)
        public func addPin(host: String, keyHash: String) -> CertificatePinningConfig.Builder {
            builderPins.append(Pin(host: host, data: keyHash, type: .key))
            return self
        }

        private func parseCertificate(pin: Pin) throws -> CredentialPin {
            // Add pin from certificate
            // It is important to take into account that this method could delay a bit the init process
            // TODO: Measure time
            guard let spki = TlsCertificateParser.spki(from: pin.data, bundle: bundle) else {
                throw errLog("Couldn't get SPKI from \(pin.data).der")
            }

            return CredentialPin(host: pin.host,
                                 hash: AlgoHelper.computeHash(spki.data, algo: .sha256),
                                 algo: .sha256)

        }

        private func parseHash(pin: Pin) throws -> CredentialPin {
            let hashComponents = pin.data.split(separator: "/")
            if hashComponents.count != 2 {
                throw errLog("Unable to add pin for host \(pin.host), invalid key hash")
            }

            let algoName = String(hashComponents[HashField.algo])
            guard let algo = KeyHashAlgo(rawValue: algoName) else {
                throw errLog("Key hash algorithm not supported for pin: \(algoName)")
            }

            let keyHash = String(hashComponents[HashField.key])
            guard let dataHash = Data(base64Encoded: keyHash) else {
                throw errLog("Key hash not valid for pin: \(algoName)")
            }
            return CredentialPin(host: pin.host, hash: dataHash, algo: algo)
        }

        private func errLog(_ message: String) -> CertificatePinningError {
            Logger.e(message)
            return CertificatePinningError(message: message)
        }
    }
}
