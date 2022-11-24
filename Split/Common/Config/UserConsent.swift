//
//  UserConsent.swift
//  Split
//
//  Created by Javier Avrudsky on 23-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

public enum UserConsent: String {
    case granted = "GRANTED"
    case declined = "DECLINED"
    case unknown = "UNKNOWN"
}

@propertyWrapper
public struct UserConsentProperty {
    private var value: String = UserConsent.granted.rawValue
    public var projectedValue: UserConsent = .granted
    public var wrappedValue: String {
        get {
            return value
        }

        set {
            setValue(newValue)
        }
    }

    public init(wrappedValue: String) {
        setValue(wrappedValue)
    }

    private mutating func setValue(_ newValue: String) {
        let uppercased = newValue.uppercased()
        guard let projectedValue = UserConsent(rawValue: uppercased) else {
            Logger.w("You passed an invalid user consent value (\(value)), " +
                     " userConsent should be one of the following values: " +
                     "'GRANTED', 'DECLINED' or 'UNKNOWN'. Defaulting to 'GRANTED' mode.")

            value = UserConsent.granted.rawValue
            projectedValue = UserConsent.granted
            return
        }
        self.value = uppercased
        self.projectedValue = projectedValue
    }

}
