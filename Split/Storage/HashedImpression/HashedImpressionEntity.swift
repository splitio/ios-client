//
//  HashedImpressionEntity+CoreDataClass.swift
//  Split
//
//  Created by Javier L. Avrudsky on 20/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//
//

import Foundation
import CoreData

@objc(HashedImpressionEntity)
class HashedImpressionEntity: NSManagedObject {
    @NSManaged public var impressionHash: Int64
    @NSManaged public var time: Int64
    @NSManaged public var createdAt: Int64
}
