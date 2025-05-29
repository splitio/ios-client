//
//  PublicKeyHeaders.swift
//  Split
//
//  Created by Javier Avrudsky on 07/06/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

enum PublicKeyHeaders {
    /*

     This file is needed because the API for RSA doesn't allow to get the SPKI.
     For that reason, the server public key is gotten from the certificate and
     then the header is added to compare with the pinned SPKI.

     Based mainly on articles:
     https://developer.apple.com/forums/thread/680554
     https://developer.apple.com/forums/thread/680572

     Keys supported by Apple are:
     - RSA
     - SECG secp256r1, aka NIST P-256
     - SECG secp384r1, aka NIST P-384
     - SECG secp521r1, aka NIST P-521
     - Curve 25519

     # Headers extraction steps bellow
     # 1 - Generating private key in pem format (2048 bits)
     openssl genpkey -algorithm RSA -out cert_private.pem -pkeyopt rsa_keygen_bits:2048

     # 2 - Getting public SPKI from cert_private.pem
     openssl rsa -pubout -in cert_private.pem -out pkey.pem

     # 3 - Getting SPKI in binary format in order to obtain the header in hexadecimal
     openssl rsa -pubin -in pkey.pem -pubout -outform DER -out pkey.der

     */

    // RSA 2048-bit Public Key Header (ASN.1 DER format)
    static let rsa2048Asn1: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0D, 0x06, 0x09,
        0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01,
        0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0F, 0x00,
    ]

    // RSA 3072-bit Public Key Header (ASN.1 DER format)
    static let rsa3072Asn1: [UInt8] = [
        0x30, 0x82, 0x01, 0xa2, 0x30, 0x0D, 0x06, 0x09,
        0x2A, 0x86, 0x48, 0x86, 0xf7, 0x0D, 0x01, 0x01,
        0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x8F, 0x00,
    ]

    // RSA 4096-bit Public Key Header (ASN.1 DER format)
    static let rsa4096Asn1: [UInt8] = [
        0x30, 0x82, 0x02, 0x22, 0x30, 0x0D, 0x06, 0x09,
        0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01,
        0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0F, 0x00,
    ]

    // ECDSA P-256 Public Key Header (ASN.1 DER format)
    static let ecdsaP256: [UInt8] = [
        0x30, 0x59, // SEQUENCE tag and length (89 bytes)
        0x30, 0x13, // SEQUENCE tag and length of algorithm identifier (19 bytes)
        0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, // OID for ecPublicKey
        0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, // OID for prime256v1 (P-256 curve)
        0x03, 0x42, 0x00, // BIT STRING tag and length (66 bytes)
        // Public key bytes (32 bytes) would follow here
    ]

    // ECDSA P-384 Public Key Header (ASN.1 DER format)
    static let ecdsaP384: [UInt8] = [
        0x30, 0x76, // SEQUENCE tag and length (118 bytes)
        0x30, 0x10, // SEQUENCE tag and length of algorithm identifier (16 bytes)
        0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, // OID for ecPublicKey
        0x06, 0x05, 0x2B, 0x81, 0x04, 0x00, 0x22, // OID for secp384r1 (P-384 curve)
        0x03, 0x62, 0x00, // BIT STRING tag and length (98 bytes)
        // Public key bytes (48 bytes) would follow here
    ]

    static let ecdsaP521: [UInt8] = [
        0x30, 0x81, 0x9b, 0x30, 0x10, 0x06, 0x07, 0x2a, 0x86,
        0x48, 0xce, 0x3d, 0x02, 0x01, 0x06, 0x05, 0x2b, 0x81,
        0x04, 0x00, 0x23, 0x03, 0x81, 0x86, 0x00,
    ]

    // Not used for now, unable to make it work yet
    // SecCertificateCopyKey does not get the key
    static let ed25519: [UInt8] = [
        0x30, 0x2a, 0x30, 0x05,
        0x06, 0x03, 0x2b, 0x65,
        0x70, 0x03, 0x21, 0x00,
    ]

    private static let headersMap: [CertKeyType: [UInt8]] = [
        .rsa2048: rsa2048Asn1,
        .rsa3072: rsa3072Asn1,
        .rsa4096: rsa4096Asn1,
        .secp256r1: ecdsaP256,
        .secp384r1: ecdsaP384,
        .secp521r1: ecdsaP521,
        .ed25519: ed25519,
    ]

    static func header(forType type: CertKeyType) -> Data? {
        if let header = headersMap[type] {
            return Data(header)
        }
        return nil
    }
}
