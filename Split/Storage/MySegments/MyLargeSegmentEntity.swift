//
//  MyLargeSegmentEntity+CoreDataClass.swift
//  Split
//
//  Created by Javier L. Avrudsky on 06/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//
//

import Foundation
import CoreData

@objc(MyLargeSegmentEntity)
class MyLargeSegmentEntity: NSManagedObject {
    @NSManaged public var body: String?
    @NSManaged public var updatedAt: Int64
    @NSManaged public var userKey: String?
}
