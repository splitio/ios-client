//
//  InfoUtils.swift
//  Pods
//
//  Created by Brian Sztamfater on 18/9/17.
//
//

import Foundation

class InfoUtils {

    static func bundleNameKey() -> String {
        guard let info = Bundle.main.infoDictionary,
            let domain = info[kCFBundleNameKey as String] as? String else {
                return "Unknown"
        }
        return domain
    }

    static func valueForKey(key: String) -> String {
        guard let info = Bundle.main.infoDictionary,
            let domain = info[key] as? String else {
            Logger.i("Cannot get \(key) key from Info.plist")
            return ""
        }
        return domain
    }
}
