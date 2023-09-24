//
//  LayoutModel.swift
//  ModelBasedLayout
//
//  Created by Matteo Ludwig on 18.07.23.
//

import UIKit


public protocol LayoutModel {
    
    // Base Layout
    var contentSize: CGSize { get }
    
    func elements(in rect: CGRect) -> [Element]
    
    func layoutAttributes(for element: Element) -> LayoutAttributes?
    
    // Animation
    func transitionAnimation(for element: Element, transition: ElementTransition) -> TransitionAnimation
    func layoutAttributes(for element: Element, frame: AnimationFrame) -> LayoutAttributes?
    
    // Content Offset Management
    func contentOffsetAnchor(in bounds: BoundsInfo) -> ContentOffsetAnchor?
    func contentOffset(for anchor: ContentOffsetAnchor, proposedBounds: BoundsInfo, currentBounds: BoundsInfo) -> CGPoint
    func contentOffset(proposedBounds: BoundsInfo, scrollingVelocity velocity: CGPoint) -> CGPoint
    
    // Self Sizing Elements
    func adjustForSelfSizing(element: Element, preferredSize: CGSize)
    
    // Dynamic Layout
    func elements(affectedByBoundsChange newBounds: BoundsInfo, in rect: CGRect) -> [Element]
    
}

public extension LayoutModel {
    
    func transitionAnimation(for element: Element, transition: ElementTransition) -> TransitionAnimation {
        return .opacity
    }
    
    func layoutAttributes(for element: Element, frame: AnimationFrame) -> LayoutAttributes? {
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
