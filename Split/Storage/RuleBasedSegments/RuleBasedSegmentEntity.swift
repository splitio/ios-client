//
//  RuleBasedSegmentEntity+CoreDataClass.swift
//  Split
//
//  Created by Split on 14/03/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import CoreData
import Foundation

@objc(RuleBasedSegmentEntity)
public class RuleBasedSegmentEntity: NSManagedObject {
    @NSManaged public var name: String
    @NSManaged public var body: String
    @NSManaged public var updatedAt: Int64
}
