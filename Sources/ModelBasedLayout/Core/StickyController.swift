//
//  StickyController.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import UIKit

class StickyController {
    
    private var boundsController: BoundsController
    private var layoutAttributesProvider: (_ element: Element) -> LayoutAttributes?
    
    private var cachedAttributes: [Element: LayoutAttributes] = [:]
    private var invalidationMap: ChunkedRectMap<Element>
    
    private var lastInvalidatedBounds: CGRect = .zero
    
    private var isBeingTransitionOut: Bool = false
    
    private(set) var usesStickyViews: Bool = false
    
    init(dataSourceCounts: DataSourceCounts,
         boundsController: BoundsController,
         layoutAttributesProvider: @escaping (_ element: Element) -> LayoutAttributes?) {
        
        self.boundsController = boundsController
        self.layoutAttributesProvider = layoutAttributesProvider
        
        self.invalidationMap = .init(chunkSize: boundsController.bounds.size)
    }
    
    func willBeReplaced() {
        self.isBeingTransitionOut = true
    }
    
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if self.usesStickyViews && self.lastInvalidatedBounds != newBounds {
            self.lastInvalidatedBounds = newBounds
            return true
        }
        return false
    }
    
    func resetCache() {
        self.cachedAttributes.removeAll(keepingCapacity: true)
        self.invalidationMap.removeAll(keepingCapacity: true)
    }
    
    private func bounds(for stickyAttributes: StickyAttributes) -> CGRect {
        (stickyAttributes.useSafeAreaInsets ? self.boundsController.visibleBounds : self.boundsController.bounds).inset(by: stickyAttributes.additionalInsets)
    }
    
    private func baseLayoutAttributes(for element: Element) -> LayoutAttributes? {
        if let attrs = self.cachedAttributes[element] {
            return attrs
        }
        
        let attrs = layoutAttributesProvider(element)
        if let attrs = attrs {
            self.cachedAttributes[element] = attrs
            
            if attrs.isSticky {
                self.usesStickyViews = true
                self.invalidationMap.insert(element, with: attrs.extendedStickyBounds!)
            }
        }
        return attrs
    }
    
    func stickify(_ attrs: LayoutAttributes) -> LayoutAttributes {
        guard attrs.isSticky && attrs.frame.width > 0 && attrs.frame.height > 0 else { return attrs }
        
        let stickyAttrs = attrs.stickyAttributes!
        
        var newAttrs = attrs
        
        let bounds = self.bounds(for: stickyAttrs)
        newAttrs.frame.ensureWithin(bounds, edges: stickyAttrs.stickyEdges)
        
        
        
        assert(stickyAttrs.stickyBounds.width >= newAttrs.frame.width && stickyAttrs.stickyBounds.height >= newAttrs.frame.height,
               "The frame of a LayoutAttributes struct must be smaller or equal in size to it's stickyBounds.")
        
        switch stickyAttrs.boundingBehaviour {
        case .push:
            newAttrs.frame.ensureWithin(stickyAttrs.stickyBounds, edges: .all)
        case .fade:
            let intersection = newAttrs.frame.intersection(stickyAttrs.stickyBounds)
            if !self.isBeingTransitionOut {
                newAttrs.alpha *= (intersection.width * intersection.height)/(newAttrs.frame.width * newAttrs.frame.height)
            }
            newAttrs.frame.ensureWithin(newAttrs.extendedStickyBounds!, edges: .all)
        case .disappear:
            newAttrs.isHidden = !newAttrs.frame.isWithin(stickyAttrs.stickyBounds, edges: .all)
        }
        
    
        
        return newAttrs
    }

    func layoutAttributes(for element: Element) -> LayoutAttributes? {
        return self.baseLayoutAttributes(for: element).map {self.stickify($0)}
    }

    func configureInvalidationContext(forBoundsChange newBounds: CGRect, with context: InvalidationContext) {
        let rect = self.boundsController.bounds.union(newBounds)
        
        let result = self.invalidationMap.query(rect).map {
            self.cachedAttributes[$0]!
        }.filter {
            return !$0.extendedStickyBounds!.isWithin(self.bounds(for: $0.stickyAttributes!), edges: $0.stickyAttributes!.stickyEdges)
        }
        
        for attrs in result {
            context.invalidateElement(attrs.element)
        }
    }
}


private extension CGRect {
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
    
    func isWithin(_ other: CGRect, edges: Edges) -> Bool {
        return !(edges.contains(.left) && self.minX < other.minX
        || edges.contains(.right) && self.maxX > other.maxX
        || edges.contains(.top) && self.minY < other.minY
        || edges.contains(.bottom) && self.maxY > other.maxY)
    }
}
