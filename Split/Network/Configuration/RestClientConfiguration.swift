//
//  RestClientConfiguration.swift
//  Split
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation
#if !COCOAPODS
import Http
#endif

struct RestClientConfiguration {
    static var httpClient: HttpClient {
        return DefaultHttpClient.shared
    }
}
