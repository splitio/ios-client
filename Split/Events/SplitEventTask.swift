//
//  SplitEventTask.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/11/18.
//

import Foundation

protocol SplitEventTask {
    var event: SplitEventWithMetadata { get }
    var runInBackground: Bool { get }
    func takeQueue() -> DispatchQueue?
    func run(_ data: Any?) -> Any? 
}
