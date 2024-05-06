//
//  LayoutModel.swift
//  ModelBasedLayout
//
//  Created by Matteo Ludwig on 18.07.23.
//

import Foundation


/// A protocol that defines the layout model of a collection view layout. The layout model is responsible for the layout of the collection view and its elements. If you want to create a custom layout, you need to implement this protocol.
public protocol LayoutModel {
    
    // MARK: Base Layout
    /// The size of the content of the layout. This is used to determine the content size of the collection view.
    var contentSize: CGSize { get }
    
    /// A function that returns the elements that are in the specified rect.
    /// - Note: This function should only return elements that are in the rect. If an element is partially in the rect, it should be included in the result. For elements that are sticky, the sticky bounds should be considered. It is generally more desirable to include elements that are not in the rect than to exclude elements that are in the rect.
    /// - Parameters: rect: The rect to check for elements.
    /// - Returns: An array of elements that are in the rect.
    func elements(in rect: CGRect) -> [Element]
    
    /// A function that returns the layout attributes for the specified element.
    /// - Parameters: element: The element to get the layout attributes for.
    /// - Returns: The layout attributes for the element.
    func layoutAttributes(for element: Element) -> LayoutAttributes?
    
    // MARK: Prepare
    /// A function that is called before the layout is calculated. It can be used to prepare caches. Most layout models do not need to implement this function.
    func prepare()
    
    // MARK: Animation
    /// A function that returns the transition animation for the specified element and transition. Per default, the transition animation is `.opacity`.
    /// - Parameters: element: The element to get the transition animation for.
    /// - Parameters: transition: The transition to get the animation for.
    /// - Returns: The transition animation for the element and transition.
    func transitionAnimation(for element: Element, transition: ElementTransition) -> ElementTransitionAnimation

    /// A function that returns the layout attributes for the specified element and frame. Implement this if you use custom element transition animations.
    /// Per default, this function calls the other `layoutAttributes(for:)` function.
    func layoutAttributes(for element: Element, frame: ElementTransitionAnimationFrame) -> LayoutAttributes?
    
    // MARK: Content Offset Management
    func contentOffsetAnchor(in bounds: BoundsInfo) -> ContentOffsetAnchor?
    func contentOffset(for anchor: ContentOffsetAnchor, proposedBounds: BoundsInfo, currentBounds: BoundsInfo) -> CGPoint
    func contentOffset(proposedBounds: BoundsInfo, scrollingVelocity velocity: CGPoint) -> CGPoint
    
    // MARK: Self Sizing Elements
    func adjustForSelfSizing(element: Element, preferredSize: CGSize)
    
    // MARK: Dynamic Layout
    func elements(affectedByBoundsChange newBounds: BoundsInfo, in rect: CGRect) -> [Element]
    
}

public extension LayoutModel {
    
    func prepare() {
        
    }
    
    func transitionAnimation(for element: Element, transition: ElementTransition) -> ElementTransitionAnimation {
        return .opacity
    }
    
    func layoutAttributes(for element: Element, frame: ElementTransitionAnimationFrame) -> LayoutAttributes? {
        return layoutAttributes(for: element)
    }
    
    func contentOffsetAnchor(in bounds: BoundsInfo) -> ContentOffsetAnchor? {
        let center = CGPoint(x: bounds.bounds.midX, y: bounds.bounds.midY)
        
        return elements(in: bounds.bounds)
            .filter { $0.elementKind == .cell }
            .compactMap { layoutAttributes(for: $0) }
            .min {
                ($0.frame.center - center).length < ($1.frame.center - center).length
            }.map {
                ContentOffsetAnchor(element: $0.element, position: $0.frame.center)
            }
    }
    
    func contentOffset(for anchor: ContentOffsetAnchor, proposedBounds: BoundsInfo, currentBounds: BoundsInfo) -> CGPoint {
        guard let attrs = self.layoutAttributes(for: anchor.element) else { return currentBounds.bounds.origin }
        
        let oldFractionalPosition = (anchor.position - currentBounds.bounds.origin) / currentBounds.bounds.size.cgPoint
        let proposedContentOffset = attrs.frame.center - oldFractionalPosition * proposedBounds.bounds.size.cgPoint
        
        return proposedContentOffset
    }
    
    func contentOffset(proposedBounds: BoundsInfo, scrollingVelocity velocity: CGPoint) -> CGPoint {
        return proposedBounds.bounds.origin
    }
    
    func adjustForSelfSizing(element: Element, preferredSize: CGSize) {
        return
    }
    
    func elements(affectedByBoundsChange newBounds: BoundsInfo, in rect: CGRect) -> [Element] {
        return []
    }
}
