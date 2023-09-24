//
//  ContentOffsetAnchor.swift
//  
//
//  Created by Matteo Ludwig on 24.09.23.
//

import Foundation


public struct ContentOffsetAnchor {
    public var element: Element
    public var position: CGPoint
    
    public init(element: Element, position: CGPoint) {
        self.element = element
        self.position = position
    }
}
