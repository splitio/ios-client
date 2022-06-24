//
//  ImpressionEntity+CoreDataClass.swift
//  Split
//
//  Created by Javier L. Avrudsky on 06/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//
//

import Foundation
import CoreData

@objc(ImpressionEntity)
class ImpressionEntity: NSManagedObject {
    @NSManaged public var storageId: String
    @NSManaged public var body: String
    @NSManaged public var createdAt: Int64
    @NSManaged public var status: Int32
    @NSManaged public var testName: String
}
