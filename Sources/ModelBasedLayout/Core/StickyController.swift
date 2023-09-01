//
//  StickyController.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import UIKit

class StickyController {
    

    private var boundsProvider: () -> CGRect
    private var layoutAttributesProvider: (_ section: Int) -> LayoutAttributes?
    
    private var cachedAttributes: [Int: LayoutAttributes] = [:]
    
    private var bounds: CGRect = .zero
    private var safeAreaInsets: UIEdgeInsets
    private var visibleBounds: CGRect = .zero
    
    private var visibleBoundsValid: Bool = false
    private(set) var isBeingTransitionOut: Bool = false
    
    private(set) var usesStickyViews: Bool = false
    
    init(dataSourceCounts: DataSourceCounts,
         geometryInfo: GeometryInfo,
         boundsProvider: @escaping () -> CGRect,
         layoutAttributesProvider: @escaping (_: Int) -> LayoutAttributes?) {
        
        self.boundsProvider = boundsProvider
        self.layoutAttributesProvider = layoutAttributesProvider
        
        self.safeAreaInsets = geometryInfo.safeAreaInsets
        self.updateVisibleBoundsIfNeeded()
        
        self.buildCachedLayoutAttributes(dataSourceCounts: dataSourceCounts)
    }
    
    private func buildCachedLayoutAttributes(dataSourceCounts: DataSourceCounts) {
        for section in 0..<dataSourceCounts.numberOfSections {
            let attrs = layoutAttributesProvider(section)
            if (attrs?.stickyEdges ?? .none) != .none {
                self.usesStickyViews = true
            }
            self.cachedAttributes[section] = attrs
        }
    }
    
    func invalidateVisibleBounds() {
        self.visibleBoundsValid = false
    }
    
     func updateVisibleBoundsIfNeeded() {
        guard !self.visibleBoundsValid && !self.isBeingTransitionOut else { return }
        
        let newBounds = self.boundsProvider()
        
        guard newBounds.size == self.bounds.size || self.bounds.size == .zero else {
            self.isBeingTransitionOut = true
            return
        }
        
        self.bounds = newBounds
        self.visibleBounds = CGRect(x: self.bounds.minX + self.safeAreaInsets.left,
                           y: self.bounds.minY + self.safeAreaInsets.top,
                           width: self.bounds.width - self.safeAreaInsets.left - self.safeAreaInsets.right,
                           height: self.bounds.height - self.safeAreaInsets.top - self.safeAreaInsets.bottom)
        self.visibleBoundsValid = true
    }
    
    func stickify(_ attrs: LayoutAttributes) -> LayoutAttributes {
        guard attrs.stickyEdges != .none else { return attrs }
        guard attrs.frame.width > 0 && attrs.frame.height > 0 else { return attrs }
        
        self.updateVisibleBoundsIfNeeded()
        
        var newAttrs = attrs
        newAttrs.frame.ensureWithin(self.visibleBounds, edges: newAttrs.stickyEdges)

        
        if let stickyBounds = attrs.stickyBounds {
            assert(stickyBounds.width >= newAttrs.frame.width && stickyBounds.height >= newAttrs.frame.height,
                   "The frame of a LayoutAttributes struct must be smaller or equal in size to it's stickyBounds.")
            
            switch attrs.stickyBoundsBehaviour {
            case .push:
                newAttrs.frame.ensureWithin(stickyBounds, edges: .all)
            case .fade:
                let intersection = newAttrs.frame.intersection(stickyBounds)
                if !self.isBeingTransitionOut {
                    newAttrs.alpha *= (intersection.width * intersection.height)/(newAttrs.frame.width * newAttrs.frame.height)
                }
                newAttrs.frame.ensureWithin(newAttrs.extendedStickyBounds!, edges: .all)
            }
            
        }
        
        return newAttrs
    }
    

    func layoutAttributes(in rect: CGRect) -> [LayoutAttributes] {
        self.updateVisibleBoundsIfNeeded()
        return cachedAttributes.values.compactMap { self.stickify($0) }.filter { $0.frame.intersects(rect) }
    }
    
    func layoutAttributes(for section: Int) -> LayoutAttributes? {
        self.updateVisibleBoundsIfNeeded()
        
        return cachedAttributes[section].map {self.stickify($0)}
    }
    
    func indexPathsToInvalidate(in rect: CGRect) -> [IndexPath] {
        self.updateVisibleBoundsIfNeeded()
        
        let result = self.layoutAttributes(in: rect).filter{ $0.stickyEdges != .none }.map { $0.indexPath }
        return result
    }
}


extension CGRect {
    mutating func ensureWithin(_ other: CGRect, edges: Edges) {
        
        if edges.contains(.left) && self.minX < other.minX {
            self.origin.x = other.origin.x
        } else if edges.contains(.right) && self.maxX > other.maxX {
            self.origin.x = other.maxX - self.width
        }
        
        
        if edges.contains(.top) && self.minY < other.minY {
            self.origin.y = other.origin.y
        } else if edges.contains(.bottom) && self.maxY > other.maxY {
            self.origin.y = other.maxY - self.height
        }
        
    }
}
