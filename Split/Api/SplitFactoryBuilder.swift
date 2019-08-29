//
//  SplitFactoryBuilder.swift
//  Split
//
//  Created by Javier L. Avrudsky on 31/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

///
/// Protocol describing the necessary components to build
/// a SplitFactory concrete implementation
///
@objc public protocol SplitFactoryBuilder {
    ///
    /// Sets the client API Key
    /// returns: the current instance of SplitFactoryBuilder implementation
    ///
    @discardableResult
    func setApiKey(_ apiKey: String) -> SplitFactoryBuilder

    ///
    /// Sets the Matching Key to use. This method is specially usefull when creating
    /// a Key without Bucketing Key. If no Matching Key or Key is set the build method
    /// will fail.
    /// - parameter matchingKey: A string representing matching key
    /// - returns: the current instance of SplitFactoryBuilder implementation
    ///
    @discardableResult
    func setMatchingKey(_ matchingKey: String) -> SplitFactoryBuilder

    ///
    /// Sets the Bucketing Key to use. This method could be used in conjunction with setMatchingKey
    /// to avoid creating explicitly a Key instance
    /// - parameter bucketingKey: A string representing bucketing key
    /// - returns: the current instance of SplitFactoryBuilder implementation
    ///
    @discardableResult
    func setBucketingKey(_ bucketingKey: String) -> SplitFactoryBuilder

    ///
    /// Sets the Key to use. This method could be used instead of setMatchingKey
    /// and setBucketing
    /// - parameter key: An instances of Key class
    /// - returns: the current instance of SplitFactoryBuilder implementation
    ///
    @discardableResult
    func setKey(_ key: Key) -> SplitFactoryBuilder

    ///
    /// Sets the Split configuration to use. If this method is avoided
    /// default configuration values will be used
    /// - parameter config: An instances of SplitConfig class
    /// - returns: the current instance of SplitFactoryBuilder implementation
    ///
    @discardableResult
    func setConfig(_ config: SplitClientConfig) -> SplitFactoryBuilder

    ///
    /// Builds the SplitFactory implementation instance based on set values
    /// - returns: An instance of SplitFactory protocol implementation
    ///
    func build() -> SplitFactory?
}
