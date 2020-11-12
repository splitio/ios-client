//
//  GeneralInfoEntity+CoreDataClass.swift
//  Split
//
//  Created by Javier L. Avrudsky on 06/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//
//

import Foundation
import CoreData

@objc(GeneralInfoEntity)
class GeneralInfoEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GeneralInfoEntity> {
        return NSFetchRequest<GeneralInfoEntity>(entityName: "GeneralInfo")
    }

    @NSManaged public var longValue: Int64
    @NSManaged public var name: String?
    @NSManaged public var stringValue: String?
    @NSManaged public var updatedAt: Int64
}
