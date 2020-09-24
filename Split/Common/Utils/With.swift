//
//  With.swift
//  Split
//
//  Created by Javier L. Avrudsky on 22/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

func with<T>(_ component: T, execute: (T) -> Void) {
    execute(component)
}
