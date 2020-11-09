//
//  MySegmentEntity+CoreDataClass.swift
//  Split
//
//  Created by Javier L. Avrudsky on 06/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//
//

import Foundation
import CoreData

@objc(MySegmentEntity)
class MySegmentEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MySegmentEntity> {
        return NSFetchRequest<MySegmentEntity>(entityName: "MySegments")
    }

    @NSManaged public var segmentList: String?
    @NSManaged public var updatedAt: Int64
    @NSManaged public var userKey: String?
}
