//
//  DebugRequest.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/7/18.
//

import Foundation
import Alamofire

extension Request {
    public func debugCurl() -> Self {
        Logger.d(self.debugDescription)
        return self
    }
}
