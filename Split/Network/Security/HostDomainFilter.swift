//
//  HostsFilter.swift
//  Split
//
//  Created by Javier Avrudsky on 30/07/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

enum HostDomainFilter {
    static let endString = "$"
    static let mainRegex = "^(?:[a-zA-Z0-9_-]+\\.)"
    static let wildCards = [
        (prefix: "**.", pattern: "\(mainRegex)*"),
        (prefix: "*.", pattern: "\(mainRegex)?"),
    ]

    static func pinsFor(host: String, pins: [CredentialPin]) -> [CredentialPin] {
        var foundPins = [CredentialPin]()
        for pin in pins {
            var hasWildcard = false
            for wildCard in wildCards {
                let count = wildCard.prefix.count
                if pin.host.starts(with: wildCard.prefix), pin.host.count > count {
                    let pinHost = pin.host
                        .suffix(starting: count)
                        .asString()
                        .replacingOccurrences(of: ".", with: "\\.")
                    let regex = "\(wildCard.pattern)\(pinHost)\(endString)"
                    if host.matchRegex(regex) {
                        foundPins.append(pin)
                    }
                    hasWildcard = true
                    continue
                }
            }
            if !hasWildcard, pin.host == host {
                foundPins.append(pin)
            }
        }
        return foundPins
    }
}
