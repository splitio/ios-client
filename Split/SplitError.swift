//
//  SplitError.swift
//  Pods
//
//  Created by Brian Sztamfater on 25/9/17.
//
//

import Foundation

enum SplitError: Error {
    case timeout(reason: String)
}
