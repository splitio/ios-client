//
//  ApiManagerProtocol.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation

protocol RestClientManagerProtocol {
    func sendRequest(target: Target,
                     parameters: [String: AnyObject]?,
                     headers: [String: String]?) -> RestClientRequestProtocol
}

extension RestClientManagerProtocol {
    func sendRequest(target: Target,
                     parameters: [String: AnyObject]? = nil) -> RestClientRequestProtocol {
        return sendRequest(target: target, parameters: parameters, headers: nil)
    }
}
