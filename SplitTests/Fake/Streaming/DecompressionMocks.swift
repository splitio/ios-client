//
//  DecompressionProviderMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
@testable import Split

class CompressionProviderMock: CompressionProvider, @unchecked Sendable {
    var decompressorCalled = false
    func decompressor(for type: CompressionType) -> CompressionUtil {
        decompressorCalled = true
        return CompressionUtilMock()
    }
}

class CompressionUtilMock: CompressionUtil, @unchecked Sendable {
    var decompressCalled = false
    func decompress(data: Data) throws -> Data {
        decompressCalled = true
        return Data()
    }
}
