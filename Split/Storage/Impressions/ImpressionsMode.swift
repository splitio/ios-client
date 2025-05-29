//
//  ImpressionsMode.swift
//  Split
//
//  Created by Javier Avrudsky on 02/07/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

public enum ImpressionsMode: String {
    case optimized = "OPTIMIZED"
    case debug = "DEBUG"
    case none = "NONE"

    func intValue() -> Int {
        switch self {
        case .optimized:
            return 0
        case .debug:
            return 1
        case .none:
            return 2
        }
    }
}

@propertyWrapper
public struct ImpressionsModeProperty {
    private var value: String = ImpressionsMode.optimized.rawValue
    public var projectedValue: ImpressionsMode = .optimized
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
        guard let projectedValue = ImpressionsMode(rawValue: uppercased) else {
            Logger.w(
                "You passed an invalid impressionsMode (\(uppercased)), " +
                    " impressionsMode should be one of the following values: " +
                    "'DEBUG', 'OPTIMIZED' or 'NONE'. Defaulting to 'OPTIMIZED' mode.")

            value = ImpressionsMode.optimized.rawValue
            projectedValue = ImpressionsMode.optimized
            return
        }
        value = uppercased
        self.projectedValue = projectedValue
    }
}
