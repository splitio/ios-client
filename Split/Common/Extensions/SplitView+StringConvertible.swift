//
//  SplitView+StringConvertible.swift
//  Split
//
//  Created by Javier on 05/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

extension SplitView {
    override public var description: String {
        var output: String = "SplitView {\n"
        if let name = name {
            output+="name = \(String(reflecting: name)) \n"
        } else {
            output+="name = nil\n"
        }
        if let defaultTreatment = defaultTreatment {
            output+="defaultTreatment = \(defaultTreatment) \n"
        } else {
            output+="defaultTreatment = nil\n"
        }
        if let trafficType = trafficType {
            output+="trafficType = \(trafficType) \n"
        } else {
            output+="trafficType = nil\n"
        }
        if let treatments = treatments {
            output+="treatments = [\(treatments.joined(separator: ","))]\n"
        } else {
            output+="treatments = nil\n"
        }
        if let prerequisites = prerequisites {
            output+="prerequisites = [\n"
            prerequisites.forEach { prerequisite in
                output+="""
                        \(prerequisite.n): {\(prerequisite.ts.joined(separator: ","))}\n
                        """
            }
            output+="]\n"
        } else {
            output+="prerequisites = nil\n"
        }
        if let sets = sets {
            output+="sets = [\(sets.joined(separator: ","))]\n"
        } else {
            output+="sets = nil\n"
        }
        if let changeNumber = changeNumber {
            output+="changeNumber = \(changeNumber) \n"
        } else {
            output+="changeNumber = nil\n"
        }
        output+="killed = \(String(describing: killed)) \n"
        output+="}"
        return output
    }
}
