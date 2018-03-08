//
//  Date+Range.swift
//  Split
//
//  Created by Natalia  Stele on 26/11/2017.
//


import Foundation


extension Date {
    
    public func isBetweeen(date date1: Date, andDate date2: Date) -> Bool {
        return date1.compare(self) == self.compare(date2)
    }
    
    public static func dateFromInt(number: Int64) -> Date {
        
        
        let time = TimeInterval(number)
        
        return Date(timeIntervalSince1970: time)
        
    }
    
}
