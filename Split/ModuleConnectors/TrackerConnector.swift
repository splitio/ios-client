//  Centralizes Tracker module imports for the Split module
//  Copyright © 2022 Split. All rights reserved.

import Foundation

#if SWIFT_PACKAGE || SPLIT_MODULAR
@_exported import Tracker
#endif

// Typealiases to keep backwards compatibility before module extraction
public typealias EventsTracker = Tracker
typealias DefaultEventsTracker = DefaultTracker
