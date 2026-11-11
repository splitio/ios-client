// ConcurrencyTestConnector.swift

#if SWIFT_PACKAGE || SPLIT_MODULAR
import SplitConcurrency

// MARK: - Concurrency types for testing

typealias Atomic = SplitConcurrency.Atomic
typealias AtomicInt = SplitConcurrency.AtomicInt
typealias SynchronizedDictionary = SplitConcurrency.SynchronizedDictionary
typealias SynchronizedDictionaryComposed = SplitConcurrency.SynchronizedDictionaryComposed
typealias SynchronizedDictionarySet = SplitConcurrency.SynchronizedDictionarySet
#endif
