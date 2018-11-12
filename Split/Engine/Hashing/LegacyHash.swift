//
//  LegacyHash.swift
//  Split
//
//  Created by Natalia  Stele on 11/10/17.
//

import Foundation

public final class LegacyHash {
    
    public static func getHash(_ key: String, _ seed: Int) -> Int {
        
        var h: Int = 0
        for character: Character in key {
            
            let value = Int(character.unicodeScalars.first!.value)
            let shifted = (h &* 31)
            h = (shifted) + value
            
        }
        
        return h ^ seed
    }
    
}

extension Character {
    var asciiValue: UInt32? {
        return String(self).unicodeScalars.filter{$0.isASCII}.first?.value
    }
}
