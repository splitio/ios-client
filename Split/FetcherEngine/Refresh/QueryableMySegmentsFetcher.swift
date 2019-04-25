//
//  QueryableMySegmentsFetcher.swift
//  Split
//
//  Created by Javier L. Avrudsky on 27/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

protocol QueryableMySegmentsFetcher {
    func isInSegments(name: String) -> Bool
}
