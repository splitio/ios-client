//  LogPrinter
//  Copyright © 2022 Split. All rights reserved.

import Foundation

/// Protocol to enable testing for Logger class
public protocol LogPrinter {
    func stdout(_ items: Any...)
}

/// Default implementation that prints to stdout
public class DefaultLogPrinter: LogPrinter {
    public init() {}
    
    public func stdout(_ items: Any...) {
        print(items)
    }
}
