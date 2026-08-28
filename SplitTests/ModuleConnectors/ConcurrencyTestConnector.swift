// ConcurrencyTestConnector.swift

#if SWIFT_PACKAGE
import Concurrency

// MARK: - Concurrency types for testing

typealias Atomic = Concurrency.Atomic
typealias AtomicInt = Concurrency.AtomicInt
typealias SynchronizedDictionary = Concurrency.SynchronizedDictionary
typealias SynchronizedDictionaryComposed = Concurrency.SynchronizedDictionaryComposed
typealias SynchronizedDictionarySet = Concurrency.SynchronizedDictionarySet
#endif
