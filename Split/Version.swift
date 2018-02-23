//
//  Version.swift
//  Split
//
//  Created by Sebastian Arrubia on 2/23/18.
//

import Foundation

class Version {
    private static let name:String = "ios"
    private static let number:String = "0.5.0"
    
    public static func toString() -> String {
        return name + "-" + number
    }
}
