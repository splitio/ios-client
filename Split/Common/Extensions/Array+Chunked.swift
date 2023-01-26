//
//  Array+Chunk.swift
//  Split
//
//  Created by Javier Avrudsky on 16-Jan-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map { start in
            Array(self[start ..< Swift.min(start + size, count)])
        }
    }
}
