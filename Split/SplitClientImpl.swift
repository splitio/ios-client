//
//  LocalSplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 20/9/17.
//
//

import Foundation

@objc public final class SplitClientImpl: NSObject, SplitClient {
    
    private let fetcher: SplitFetcher
    private let persistence: SplitPersistence
    private var keys: [Key]?
    private var attributes: [String : Any]?
    
    public init(splitFetcher: SplitFetcher, splitPersistence: SplitPersistence, keys: [Key]? = nil, attributes: [String : Any]? = nil) {
        self.fetcher = splitFetcher
        self.persistence = splitPersistence
        self.keys = keys
        self.attributes = attributes
    }
    
    public func getTreatment(forSplit split: String) -> String {
        guard let treatment = self.persistence.get(key: split) else {
            return "control" // TODO: Move to a constant on another class
        }
        return treatment
    }
    
    public func updateKeys(keys: [Key], attributes: [String : Any]? = nil) {
        self.keys = keys
        self.attributes = attributes
        persistence.removeAll()
        refresh()
    }
    
    func refresh() {
        guard let keys = self.keys else {
            return
        }
        fetcher.fetchAll(keys: keys, attributes: self.attributes) { [weak self] treatments in
            guard let strongSelf = self else {
                return
            }
            treatments.forEach { strongSelf.persistence.save(key: $0.name, value: $0.treatment) }
        }
    }
    
}
