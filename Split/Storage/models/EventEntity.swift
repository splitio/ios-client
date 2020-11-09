//
//  EventEntity+CoreDataClass.swift
//  Split
//
//  Created by Javier L. Avrudsky on 06/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//
//

import Foundation
import CoreData

@objc(EventEntity)
class EventEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventEntity> {
        return NSFetchRequest<EventEntity>(entityName: "Events")
    }

    @NSManaged public var body: String?
    @NSManaged public var createdAt: Int64
    @NSManaged public var name: String?
    @NSManaged public var status: Int32
}
