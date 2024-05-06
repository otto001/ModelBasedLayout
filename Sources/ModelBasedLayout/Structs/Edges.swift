//
//  Edges.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import Foundation

/// A set of edges. Used to specify the edges of a rectangle. Options are `top`, `bottom`, `left`, and `right`.
public struct Edges: OptionSet {
    public let rawValue: UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    /// The top edge.
    public static let top = Edges(rawValue: 1 << 0)
    
    /// The bottom edge.
    public static let bottom = Edges(rawValue: 1 << 1)

    /// The left edge.
    public static let left = Edges(rawValue: 1 << 2)

    /// The right edge.
    public static let right = Edges(rawValue: 1 << 3)
    
    /// A convenience option set that contains no edges.
    public static let none: Edges = []

    /// A convenience option set that contains all edges.
    public static let all: Edges = [.top, .left, bottom, .right]
}
