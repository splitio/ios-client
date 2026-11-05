// ConcurrencyTestConnector.swift

#if SWIFT_PACKAGE || SPLIT_MODULAR
import Concurrency

// MARK: - Concurrency types for testing

typealias Atomic = Concurrency.Atomic
typealias AtomicInt = Concurrency.AtomicInt
typealias SynchronizedDictionary = Concurrency.SynchronizedDictionary
typealias SynchronizedDictionaryComposed = Concurrency.SynchronizedDictionaryComposed
typealias SynchronizedDictionarySet = Concurrency.SynchronizedDictionarySet
#endif
