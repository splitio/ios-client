//
//  UserConsent.swift
//  Split
//
//  Created by Javier Avrudsky on 23-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@objc public enum UserConsent: Int {
    case granted = 0
    case declined = 1
    case unknown = 2

    static func fromString(_ value: String) -> UserConsent? {
        switch value.uppercased() {
        case "GRANTED":
            return .granted
        case "DECLINED":
            return .declined
        case "UNKNOWN":
            return .unknown
        case "GRANTED":
            return .granted
        default:
            return nil
        }
    }

    var stringValue: String {
        switch self {
        case .declined:
            return "DECLINED"
        case .unknown:
            return "UNKNOWN"
        default:
            return "GRANTED"
        }
    }
}

@propertyWrapper
public struct UserConsentProperty {
    private var value: String = UserConsent.granted.stringValue
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
        guard let projectedValue = UserConsent.fromString(newValue) else {
            Logger.w("You passed an invalid user consent value (\(value)), " +
                     " userConsent should be one of the following values: " +
                     "'GRANTED', 'DECLINED' or 'UNKNOWN'. Defaulting to 'GRANTED' mode.")

            value = UserConsent.granted.stringValue
            projectedValue = UserConsent.granted
            return
        }
        self.value = uppercased
        self.projectedValue = projectedValue
    }

}
