//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import Foundation


public struct Edges: OptionSet {
    public let rawValue: UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    public static let top = Edges(rawValue: 1 << 0)
    public static let bottom = Edges(rawValue: 1 << 1)
    public static let left = Edges(rawValue: 1 << 2)
    public static let right = Edges(rawValue: 1 << 3)
    
    public static let none: Edges = []
    public static let all: Edges = [.top, .left, bottom, .right]
}
