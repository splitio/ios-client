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
    @NSManaged public var longValue: Int64
    @NSManaged public var name: String
    @NSManaged public var stringValue: String?
    @NSManaged public var updatedAt: Int64
}
