//
//  SplitFactory.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

///
/// This protocol was renamed from SplitFactoryProtocol to SplitFactory
/// to follow Swift guidelines
/// Also all methods where replaced by read only variables following Uniform Access Principle
///
@objc public protocol SplitFactory {

    ///
    /// Current Split client instance
    /// - returns: An instance of a class implementing SplitClient protocol
    ///
    var client: SplitClient { get }

    ///
    /// Current Split manager instance
    /// - returns: An instance of a class implementing SplitManager protocol
    ///
    var manager: SplitManager { get }

    ///
    /// Current Split SDK Version
    /// - returns: A String representation of the current SDK version
    ///
    var version: String { get }
}
