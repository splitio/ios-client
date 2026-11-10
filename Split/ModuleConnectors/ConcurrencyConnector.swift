//  Concurrency module imports for the Split module

#if SWIFT_PACKAGE || SPLIT_MODULAR

import SplitConcurrency

// MARK: - Internal use
typealias Atomic = SplitConcurrency.Atomic
typealias AtomicInt = SplitConcurrency.AtomicInt
typealias SynchronizedDictionary = SplitConcurrency.SynchronizedDictionary
typealias SynchronizedDictionaryComposed = SplitConcurrency.SynchronizedDictionaryComposed
typealias SynchronizedDictionarySet = SplitConcurrency.SynchronizedDictionarySet
#endif
