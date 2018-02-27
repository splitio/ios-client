//
//  ImpressionDTO.swift
//  Split
//
//  Created by Natalia  Stele on 03/01/2018.
//

import Foundation
//import ObjectMapper

public class ImpressionDTO: Codable {
    
    public var keyName: String?
    public var treatment: String?
    public var time: Int64?
    public var changeNumber: Int64?
    public var label: String?
    public var bucketingKey: String?
    
    
    enum CodingKeys: String, CodingKey {
        
        case keyName = "keyName"
        case treatment = "treatment"
        case time = "time"
        case changeNumber = "changeNumber"
        case label = "label"
        case bucketingKey = "bucketingKey"
 
    }
        
}
