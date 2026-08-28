//  HostDomainFilter
//  Created by Javier Avrudsky on 30/07/2024.
//  Copyright © 2024 Split. All rights reserved.

import Foundation

#if SWIFT_PACKAGE
private extension String {
    func matchRegex(_ pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        return regex.firstMatch(in: self, range: NSRange(startIndex..<endIndex, in: self)) != nil
    }
}
#endif

public struct HostDomainFilter {
    public static let endString = "$"
    public static let mainRegex = "^(?:[a-zA-Z0-9_-]+\\.)"
    public static let wildCards = [(prefix: "**.", pattern: "\(mainRegex)*"), (prefix: "*.", pattern: "\(mainRegex)?")]

    public static func pinsFor(host: String, pins: [CredentialPin]) -> [CredentialPin] {
        var foundPins = [CredentialPin]()
        for pin in pins {
            var hasWildcard = false
            for wildCard in wildCards {
                let count = wildCard.prefix.count
                if pin.host.starts(with: wildCard.prefix), pin.host.count > count {
                    // Extract the host suffix after the wildcard prefix (e.g., "**.example.com" -> "example.com")
                    let pinHost = String(pin.host.suffix(from: pin.host.index(pin.host.startIndex, offsetBy: count)))
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
