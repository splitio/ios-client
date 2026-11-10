//  Created by Sebastian Arrubia on 3/5/18.

#if SWIFT_PACKAGE || SPLIT_MODULAR
import SplitLogging

// Re-export Logger from Logging module for backward compatibility
// This allows existing Split code to continue using Logger.* without changes
typealias Logger = SplitLogging.Logger

// Use Logging's TimeChecker implementation.
typealias TimeChecker = SplitLogging.TimeChecker

// LogPrinter and DefaultLogPrinter are now in the Logging module
// Re-export for backward compatibility
typealias LogPrinter = SplitLogging.LogPrinter
typealias DefaultLogPrinter = SplitLogging.DefaultLogPrinter
#endif
