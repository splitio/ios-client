//
//  ImpressionsCountEntity.swift
//  Split
//
//  Created by Javier Avrudsky on 29/06/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
import CoreData

@objc(ImpressionsCountEntity)
class ImpressionsCountEntity: NSManagedObject {
    @NSManaged public var storageId: String
    @NSManaged public var body: String
    @NSManaged public var createdAt: Int64
    @NSManaged public var status: Int32
}
