//
//  StickyController.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import UIKit

class StickyController {
    
    let stickyEdges: Edges

    private var visibleBoundsProvider: () -> CGRect
    private var layoutAttributesProvider: (_ section: Int) -> LayoutAttributes?
    
    private var cachedAttributes: [Int: LayoutAttributes] = [:]
    
    init(stickyEdges: Edges, dataSourceCounts: DataSourceCounts, visibleBoundsProvider: @escaping () -> CGRect, layoutAttributesProvider: @escaping (_: Int) -> LayoutAttributes?) {
        
        self.stickyEdges = stickyEdges
        
        self.visibleBoundsProvider = visibleBoundsProvider
        self.layoutAttributesProvider = layoutAttributesProvider
        
        self.buildCachedLayoutAttributes(dataSourceCounts: dataSourceCounts)
    }
    
    func buildCachedLayoutAttributes(dataSourceCounts: DataSourceCounts) {
        guard self.stickyEdges != .none else { return }
        
        
        for section in 0..<dataSourceCounts.numberOfSections {
            self.cachedAttributes[section] = layoutAttributesProvider(section)
        }
    }
    
    private func stickify(_ attrs: LayoutAttributes) -> LayoutAttributes {
        guard self.stickyEdges != .none else { return attrs }
        let visibleBounds = self.visibleBoundsProvider()
        
        var newAttrs = attrs
        
        if self.stickyEdges.contains(.left) && attrs.frame.minX < visibleBounds.minX {
            newAttrs.frame.origin.x = visibleBounds.origin.x
        }
        if self.stickyEdges.contains(.top) && attrs.frame.minY < visibleBounds.minY {
            newAttrs.frame.origin.y = visibleBounds.origin.y
        }
        if self.stickyEdges.contains(.right) && attrs.frame.maxX > visibleBounds.maxX {
            newAttrs.frame.origin.x = visibleBounds.maxX - newAttrs.frame.width
        }
        if self.stickyEdges.contains(.bottom) && attrs.frame.maxY > visibleBounds.maxY {
            newAttrs.frame.origin.y = visibleBounds.maxY - newAttrs.frame.height
        }
        
        return newAttrs
    }
    

    
    func layoutAttributes(in rect: CGRect, visibleSections: [Int]) -> [LayoutAttributes] {
        guard self.stickyEdges != .none else {
            return visibleSections.compactMap { layoutAttributesProvider($0) }.filter { $0.frame.intersects(rect) }
        }
        
        return cachedAttributes.values.compactMap { self.stickify($0) }.filter { $0.frame.intersects(rect) }
    }
    
    func layoutAttributes(for section: Int) -> LayoutAttributes? {
        guard self.stickyEdges != .none else {
            return layoutAttributesProvider(section)
        }
        
        return cachedAttributes[section].map {self.stickify($0)}
    }
    
    func indexPathsToInvalidate(in rect: CGRect) -> [IndexPath] {
        guard self.stickyEdges != .none else { return [] }
        
        return self.layoutAttributes(in: rect, visibleSections: []).map { $0.indexPath }
    }
}
