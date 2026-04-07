//  Concurrency module imports for the Split module

#if !COCOAPODS

import Concurrency

// MARK: - Internal use
typealias Atomic = Concurrency.Atomic
typealias AtomicInt = Concurrency.AtomicInt
typealias SynchronizedDictionary = Concurrency.SynchronizedDictionary
typealias SynchronizedDictionaryComposed = Concurrency.SynchronizedDictionaryComposed
typealias SynchronizedDictionarySet = Concurrency.SynchronizedDictionarySet
#endif
