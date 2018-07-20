//
//  ImpressionsHit.swift
//  Split
//
//  Created by Natalia  Stele on 08/01/2018.
//

import Foundation

public class ImpressionsHit: Codable {
    
    public var testName: String?
    public var keyImpressions: [Impression]?
    
    
    enum CodingKeys: String, CodingKey {
        
        case testName = "testName"
        case keyImpressions = "keyImpressions"
        
    }

}
