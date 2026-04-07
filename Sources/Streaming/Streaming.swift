import Foundation
#if !COCOAPODS
import Http
import Logging
#endif

public struct StreamingInternal {
    public init() {}
    public func action() {
        print("Streaming ready.")
        HttpInternal().action()
        LoggingInternal().action()
    }
}