//
//  HashedImpressionEntity+CoreDataClass.swift
//  Split
//
//  Created by Javier L. Avrudsky on 20/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//
//

import CoreData
import Foundation

@objc(HashedImpressionEntity)
class HashedImpressionEntity: NSManagedObject {
    @NSManaged public var impressionHash: UInt32
    @NSManaged public var time: Int64
    @NSManaged public var createdAt: Int64
}
