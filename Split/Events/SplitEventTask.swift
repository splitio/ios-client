//
//  SplitEventTask.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/11/18.
//

import Foundation

protocol SplitEventTask {
    var event: SplitEvent { get }
    var runInBackground: Bool { get }
    func takeQueue() -> DispatchQueue?
    func run(_ metadata: EventMetadata?)
}
