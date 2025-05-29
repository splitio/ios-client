//
//  Cov.swift
//  Split
//
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation

/// A utility class to demonstrate code coverage in SonarQube
public class Cov {
    
    /// Checks if a number is even
    /// - Parameter input: The number to check
    /// - Returns: True if the number is even, false otherwise
    public static func isEven(input: Int) -> Bool {
        return input % 2 == 0
    }
    
    /// Checks if a number is positive
    /// - Parameter input: The number to check
    /// - Returns: True if the number is positive, false otherwise
    public static func isPositive(input: Int) -> Bool {
        return input > 0
    }
    
    /// Calculates the factorial of a number
    /// - Parameter n: The number to calculate factorial for
    /// - Returns: The factorial of the number
    public static func factorial(n: Int) -> Int {
        if n <= 1 {
            return 1
        } else {
            return n * factorial(n: n - 1)
        }
    }
    
    /// Checks if a string is a palindrome
    /// - Parameter text: The string to check
    /// - Returns: True if the string is a palindrome, false otherwise
    public static func isPalindrome(text: String) -> Bool {
        let cleanText = text.lowercased().filter { $0.isLetter }
        return cleanText == String(cleanText.reversed())
    }
    
    /// Finds the maximum value in an array of integers
    /// - Parameter numbers: The array of integers
    /// - Returns: The maximum value, or nil if the array is empty
    public static func findMax(numbers: [Int]) -> Int? {
        if numbers.isEmpty {
            return nil
        }
        
        var max = numbers[0]
        for number in numbers {
            if number > max {
                max = number
            }
        }
        
        return max
    }
    
    /// Converts a temperature from Celsius to Fahrenheit
    /// - Parameter celsius: The temperature in Celsius
    /// - Returns: The temperature in Fahrenheit
    public static func celsiusToFahrenheit(celsius: Double) -> Double {
        return (celsius * 9/5) + 32
    }
}
