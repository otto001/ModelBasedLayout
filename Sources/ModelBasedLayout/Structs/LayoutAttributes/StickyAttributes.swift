//
//  StickyAttributes.swift
//  
//
//  Created by Matteo Ludwig on 01.09.23.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// The sticky attributes of an element. Contains information about the element's sticky edges, bounds, and bounding behaviour. Must be supplied to the layout attributes for elements that should stick to the edges of the collection view.
public struct StickyAttributes {
    /// How the element should behave once it reaches the sticky edges.
    public enum BoundingBehaviour: Codable {

        /// The element will stick to the sticky edges as long as it remains fully within the sticky bounds.
        case push

        /// The element will fade out using opacity when it reaches the sticky edges. For this, the element will be allowed to move out of the sticky bounds by the size of its own frame. Once the frame and sticky bounds no longer intersect, the element will be fully hidden.
        case fade

        /// The element will disappear when it reaches the sticky edges.
        case disappear
    }
    
    /// The edges that the element should stick to. If no edges are specified, the element will not stick to any edges.
    public var stickyEdges: Edges

    /// The bounds within the element is allowed to stick to the edges. The behaviour of the view once it reaches the stickyBounds is determined by the `boundingBehaviour` property. If the view should always be visible, this property is allowed to use infinite values.
    public var stickyBounds: CGRect
    /// How the element should behave once it reaches the sticky edges.
    public var boundingBehaviour: BoundingBehaviour
    
    /// Additional insets that should be applied to the bounds of the collection view when sticking to its edges.
    public var additionalInsets: NativeEdgeInsets

    /// A boolean value that determines if the element should respect the safe area insets of the collection view when sticking to its edges.
    public var useSafeAreaInsets: Bool
    
    /// Initializes the sticky attributes with the specified values.
    /// - Parameters: stickyEdges: The edges that the element should stick to. If no edges are specified, the element will not stick to any edges.
    /// - Parameters: stickyBounds: The bounds within the element is allowed to stick to the edges. The behaviour of the view once it reaches the stickyBounds is determined by the `boundingBehaviour` property.
    /// - Parameters: boundingBehaviour: How the element should behave once it reaches the sticky edges.
    /// - Parameters: additionalInsets: Additional insets that should be applied to the bounds of the collection view when sticking to its edges.
    /// - Parameters: useSafeAreaInsets: A boolean value that determines if the element should respect the safe area insets of the collection view when sticking to its edges.
    public init(stickyEdges: Edges = .all,
                stickyBounds: CGRect = .zero,
                boundingBehaviour: BoundingBehaviour = .push,
                additionalInsets: NativeEdgeInsets = NativeEdgeInsets(),
                useSafeAreaInsets: Bool = true) {
        self.stickyEdges = stickyEdges
        self.stickyBounds = stickyBounds
        self.boundingBehaviour = boundingBehaviour
        self.useSafeAreaInsets = useSafeAreaInsets
        self.additionalInsets = additionalInsets
    }
}
