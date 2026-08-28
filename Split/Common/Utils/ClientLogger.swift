//  Created by Sebastian Arrubia on 3/5/18.

#if SWIFT_PACKAGE
import Logging

// Re-export Logger from Logging module for backward compatibility
// This allows existing Split code to continue using Logger.* without changes
typealias Logger = Logging.Logger

// Use Logging's TimeChecker implementation.
typealias TimeChecker = Logging.TimeChecker

// LogPrinter and DefaultLogPrinter are now in the Logging module
// Re-export for backward compatibility
typealias LogPrinter = Logging.LogPrinter
typealias DefaultLogPrinter = Logging.DefaultLogPrinter
#endif
