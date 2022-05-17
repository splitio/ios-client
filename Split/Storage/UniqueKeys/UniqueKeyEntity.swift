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
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UniqueKeyEntity> {
        return NSFetchRequest<UniqueKeyEntity>(entityName: "UniqueKeys")
    }

    @NSManaged public var featureList: String?
    @NSManaged public var updatedAt: Int64
    @NSManaged public var userKey: String?
}
