//
//  SplitError.swift
//  Split
//
//  Created by Brian Sztamfater on 25/9/17.
//
//

import Foundation

@objc enum SplitError: Int, Error {
    case timeout
    case matcherNoFound

}
