//
//  UniqueKeyEntity+CoreDataClass.swift
//  Split
//
//  Created by Javier L. Avrudsky on 06/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//
//

import Foundation
import CoreData

@objc(UniqueKeyEntity)
class UniqueKeyEntity: NSManagedObject {

    @NSManaged public var storageId: String
    @NSManaged public var userKey: String
    @NSManaged public var featureList: String
    @NSManaged public var createdAt: Int64
    @NSManaged public var sendAttemptCount: Int16
    @NSManaged public var status: Int32
}
