//
//  PeriodicTaskProtocol.swift
//  Split
//
//  Created by Javier on 01/10/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

protocol PeriodicDataTaskProtocol {
    func start()
    func stop()
    func executePeriodicAction()
    func loadDataFromDisk()
    func saveDataToDisk()
}

