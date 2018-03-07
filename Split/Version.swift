//
//  Version.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/1/18.
//

import Foundation

class Version {
    private static let name:String = "ios"
    private static let number:String = "0.1.0"
    
    public static func toString() -> String {
        return name + "-" + number
    }
}
