//
//  StickyController.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import UIKit

class StickyController {
    
    struct ItemKey: Hashable {
        var elementKind: ElementKind
        var indexPair: IndexPair
    }
    
    private var boundsProvider: () -> CGRect
    private var layoutAttributesProvider: (_ elementKind: ElementKind, _ indexPair: IndexPair) -> LayoutAttributes?
    
    private var cachedAttributes: [ItemKey: LayoutAttributes] = [:]
    private var invalidationMap: ChunkedRectMap<ItemKey>
    
    private var bounds: CGRect = .zero
    private var safeAreaInsets: UIEdgeInsets
    private var visibleBounds: CGRect = .zero
    
    private var visibleBoundsValid: Bool = false
    private(set) var isBeingTransitionOut: Bool = false
    
    private(set) var usesStickyViews: Bool = false
    
    init(dataSourceCounts: DataSourceCounts,
         geometryInfo: GeometryInfo,
         boundsProvider: @escaping () -> CGRect,
         layoutAttributesProvider: @escaping (_ elementKind: ElementKind, _ indexPair: IndexPair) -> LayoutAttributes?) {
        
        self.boundsProvider = boundsProvider
        self.layoutAttributesProvider = layoutAttributesProvider
        
        self.safeAreaInsets = geometryInfo.safeAreaInsets
        self.invalidationMap = .init(chunkSize: boundsProvider().size)
        self.updateVisibleBoundsIfNeeded()
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
    
    private func bounds(for stickyAttributes: StickyAttributes) -> CGRect {
        (stickyAttributes.useSafeAreaInsets ? self.visibleBounds : self.bounds).inset(by: stickyAttributes.additionalInsets)
    }
    
    private func baseLayoutAttributes(forItemOfKind elementKind: ElementKind, at indexPair: IndexPair) -> LayoutAttributes? {
        let key = ItemKey(elementKind: elementKind, indexPair: indexPair)
        if let attrs = self.cachedAttributes[key] {
            return attrs
        }
        
        let attrs = layoutAttributesProvider(elementKind, indexPair)
        if let attrs = attrs {
            self.cachedAttributes[key] = attrs
            
            if attrs.isSticky {
                self.usesStickyViews = true
                self.invalidationMap.insert(key, with: attrs.extendedStickyBounds!)
            }
        }
        return attrs
    }
    
    private func stickify(_ attrs: LayoutAttributes) -> LayoutAttributes {
        guard attrs.isSticky && attrs.frame.width > 0 && attrs.frame.height > 0 else { return attrs }
        
        let stickyAttrs = attrs.stickyAttributes!
        self.updateVisibleBoundsIfNeeded()
        
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
        }
        
    
        
        return newAttrs
    }
    

    func layoutAttributes(forItemOfKind elementKind: ElementKind, at indexPair: IndexPair) -> LayoutAttributes? {
        self.updateVisibleBoundsIfNeeded()
        return self.baseLayoutAttributes(forItemOfKind: elementKind, at: indexPair).map {self.stickify($0)}
    }

    func configureInvalidationContext(forBoundsChange newBounds: CGRect, with context: UICollectionViewLayoutInvalidationContext) {
        let rect = boundsProvider().union(newBounds)
        self.updateVisibleBoundsIfNeeded()
        
        let result = self.invalidationMap.query(rect).map {
            self.cachedAttributes[$0]!
        }.filter {
            return !$0.extendedStickyBounds!.isWithin(self.bounds(for: $0.stickyAttributes!), edges: $0.stickyAttributes!.stickyEdges)
        }
        
        for attrs in result {
            switch attrs.elementKind {
            case .header:
                context.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader, at: [attrs.indexPair.indexPath])
            case .footer:
                context.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionFooter, at: [attrs.indexPair.indexPath])
            case .additionalSupplementaryView(let elementKind):
                context.invalidateSupplementaryElements(ofKind: elementKind, at: [attrs.indexPair.indexPath])
            default:
                break
            }
            
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
