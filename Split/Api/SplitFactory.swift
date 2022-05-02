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
    /// Default Split client instance. This would be the first client created on factory init
    /// - Returns: An instance of a class implementing SplitClient protocol
    ///
    var client: SplitClient { get }

    ///
    /// Allows getting a new client instance for other Key using the current created factory
    /// - Parameter key: The corresponding Key object for this new SplitClient
    /// - Returns: An instance of a class implementing SplitClient protocol
    ///
    func client(key: Key) -> SplitClient

    ///
    /// Allows getting a new client instance for other Key using the current created factory
    ///
    /// - Parameter matchingKey: A matching key to create a Key object for this new SplitClient
    /// - Returns: An instance of a class implementing SplitClient protocol
    ///
    @objc(clientWithMatchingKey:)
    func client(matchingKey: String) -> SplitClient

    ///
    /// Allows getting a new client instance for other Key using the current created factory
    ///
    /// - Parameters:
    ///     - matchingKey: The matching key to create a Key object for this new SplitClient
    ///     - bucketingKey: The bucketing key to create a Key object for this new SplitClient
    /// - Returns: An instance of a class implementing SplitClient protocol
    @objc(clientWithMatchingKey:bucketingKey:)
    func client(matchingKey: String, bucketingKey: String?) -> SplitClient

    ///
    /// Current Split manager instance
    /// - Returns: The current instance of a class implementing SplitManager protocol
    ///
    var manager: SplitManager { get }

    ///
    /// Current Split SDK Version
    /// - Returns: A String representation of the current SDK version
    ///
    var version: String { get }
}
