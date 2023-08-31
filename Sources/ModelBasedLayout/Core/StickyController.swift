//
//  StickyController.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import UIKit

class StickyController {
    
    let stickyEdges: Edges

    private var boundsProvider: () -> CGRect
    private var layoutAttributesProvider: (_ section: Int) -> LayoutAttributes?
    
    private var cachedAttributes: [Int: LayoutAttributes] = [:]
    
    private var bounds: CGRect = .zero
    private var safeAreaInsets: UIEdgeInsets
    private var visibleBounds: CGRect = .zero
    
    private var visibleBoundsValid: Bool = false
    private(set) var frozen: Bool = false
    
    init(stickyEdges: Edges,
         dataSourceCounts: DataSourceCounts,
         geometryInfo: GeometryInfo,
         boundsProvider: @escaping () -> CGRect,
         layoutAttributesProvider: @escaping (_: Int) -> LayoutAttributes?) {
        
        self.stickyEdges = stickyEdges
        
        self.boundsProvider = boundsProvider
        self.layoutAttributesProvider = layoutAttributesProvider
        
        self.safeAreaInsets = geometryInfo.safeAreaInsets
        self.updateVisibleBoundsIfNeeded()
        
        self.buildCachedLayoutAttributes(dataSourceCounts: dataSourceCounts)
    }
    
    private func buildCachedLayoutAttributes(dataSourceCounts: DataSourceCounts) {
        for section in 0..<dataSourceCounts.numberOfSections {
            self.cachedAttributes[section] = layoutAttributesProvider(section)
        }
    }
    
    func invalidateVisibleBounds() {
        self.visibleBoundsValid = false
    }
    
    private func freezeLayoutAttributes() {
        self.frozen = true
    }
    
     func updateVisibleBoundsIfNeeded() {
        guard !self.visibleBoundsValid && !self.frozen else { return }
        
        let newBounds = self.boundsProvider()
        
        guard newBounds.size == self.bounds.size || self.bounds.size == .zero else {
            self.freezeLayoutAttributes()
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
        guard self.stickyEdges != .none else { return attrs }
        self.updateVisibleBoundsIfNeeded()
        
        var newAttrs = attrs
        
        if self.stickyEdges.contains(.left) && attrs.frame.minX < self.visibleBounds.minX {
            newAttrs.frame.origin.x = self.visibleBounds.origin.x
        }
        if self.stickyEdges.contains(.top) && attrs.frame.minY < self.visibleBounds.minY {
            newAttrs.frame.origin.y = self.visibleBounds.origin.y
        }
        if self.stickyEdges.contains(.right) && attrs.frame.maxX > self.visibleBounds.maxX {
            newAttrs.frame.origin.x = self.visibleBounds.maxX - newAttrs.frame.width
        }
        if self.stickyEdges.contains(.bottom) && attrs.frame.maxY > self.visibleBounds.maxY {
            newAttrs.frame.origin.y = self.visibleBounds.maxY - newAttrs.frame.height
        }
        
        return newAttrs
    }
    

    func layoutAttributes(in rect: CGRect) -> [LayoutAttributes] {
        self.updateVisibleBoundsIfNeeded()
        return cachedAttributes.values.compactMap { self.stickify($0) }.filter { $0.frame.intersects(rect) }
    }
    
    func layoutAttributes(for section: Int) -> LayoutAttributes? {
        self.updateVisibleBoundsIfNeeded()
        guard self.stickyEdges != .none else {
            return layoutAttributesProvider(section)
        }
        
        return cachedAttributes[section].map {self.stickify($0)}
    }
    
    func indexPathsToInvalidate(in rect: CGRect) -> [IndexPath] {
        self.updateVisibleBoundsIfNeeded()
        guard self.stickyEdges != .none else { return [] }
        
        let result = self.layoutAttributes(in: rect).map { $0.indexPath }
        return result
    }
}
