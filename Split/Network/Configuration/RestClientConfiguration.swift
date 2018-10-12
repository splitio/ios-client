//
//  RestClientConfiguration.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation

struct RestClientConfiguration {
    static var manager: RestClientManagerProtocol {
        return HttpSession.shared
    }
}
