//
//  DynamicTarget.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/2/18.
//

import Foundation

class DynamicTarget: Target {
    var sdkBaseUrl: URL
    
    var eventsBaseURL: URL
    
    var apiKey: String?
    
    var commonHeaders: [String : String]?
    
    var method: HTTPMethod
    
    var url: URL
    
    var errorSanitizer: (JSON, Int) -> Result<JSON>
    
    
}
