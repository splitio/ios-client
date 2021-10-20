//
//  Bundle+Finder.swift
//  Split
//
//  Created by Javier Avrudsky on 22/02/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

private class BundleFinder {}

extension Foundation.Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    static var split: Bundle = {
        let bundleName = Bundle.splitBundleName

        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: BundleFinder.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }

        return Bundle(for: CoreDataHelperBuilder.self)
    }()
}
