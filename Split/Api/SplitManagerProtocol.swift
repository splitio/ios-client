//
//  SplitManagerProtocol.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

@objc public protocol SplitManagerProtocol {
    var splits: [SplitView] { get }
    var splitNames: [String] { get }
    func split(featureName: String) -> SplitView?
}
