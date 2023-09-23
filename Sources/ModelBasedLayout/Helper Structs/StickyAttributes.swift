//
//  StickyAttributes.swift
//  
//
//  Created by Matteo Ludwig on 01.09.23.
//

import UIKit


public struct StickyAttributes {
    public enum BoundingBehaviour {
        case push, fade, disappear
    }
    
    public var stickyEdges: Edges
    public var stickyBounds: CGRect
    public var boundingBehaviour: BoundingBehaviour
    
    public var additionalInsets: UIEdgeInsets
    public var useSafeAreaInsets: Bool
    
    public init(stickyEdges: Edges = .all,
                stickyBounds: CGRect = .zero,
                boundingBehaviour: BoundingBehaviour = .push,
                additionalInsets: UIEdgeInsets = .zero,
                useSafeAreaInsets: Bool = true) {
        self.stickyEdges = stickyEdges
        self.stickyBounds = stickyBounds
        self.boundingBehaviour = boundingBehaviour
        self.useSafeAreaInsets = useSafeAreaInsets
        self.additionalInsets = additionalInsets
    }
}
