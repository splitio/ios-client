//
//  SplitManager.swift
//  Split
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

@objc public protocol SplitManager {
    var splits: [SplitView] { get }
    var splitNames: [String] { get }
    func split(featureName: String) -> SplitView?
}
