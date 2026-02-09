import Foundation
#if !COCOAPODS
import Logging
#endif

public struct HttpInternal {
    public init() {}
    public func action() {
        print("Http ready.")
        LoggingInternal().action()
    }
}