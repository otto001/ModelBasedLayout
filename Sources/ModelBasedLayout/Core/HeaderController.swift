//
//  HeaderController.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import UIKit

class HeaderLayoutData {
    private var baseHeaderAttributesCache: [UICollectionViewLayoutAttributes] = []
    
    private var lazyBaseHeaderAttributes: LazyMapSequence<LazySequence<(Range<Int>)>.Elements, UICollectionViewLayoutAttributes> {
        (0..<self.numberOfSections).lazy.map {
            self.baseHeaderLayoutAttributes(for: $0)
        }
    }
    
    private(set) var numberOfSections: Int
    private(set) var zIndexOffset: Int
    private var visibleBoundsProvider: () -> CGRect
    private var verticalPositionProvider: (_ section: Int) -> CGFloat
    private var headerReferenceSize: CGSize
    
    init(numberOfSections: Int,
         zIndexOffset: Int,
         visibleBoundsProvider: @escaping () -> CGRect,
         verticalPositionProvider: @escaping (_ section: Int) -> CGFloat) {
        
        self.numberOfSections = numberOfSections
        self.zIndexOffset = zIndexOffset
        self.visibleBoundsProvider = visibleBoundsProvider
        self.verticalPositionProvider = verticalPositionProvider
        
        self.headerReferenceSize = CGSize(width: 200, height: 20)
    }
    
    private func makeBaseHeaderLayoutAttributes(for section: Int) -> UICollectionViewLayoutAttributes {
        
        let size = self.headerReferenceSize
        let verticalPosition = max(0, self.verticalPositionProvider(section) - size.height/4)
        let origin = CGPoint(x: 0, y: verticalPosition)
        let frame = CGRect(origin: origin, size: size)
        
        let attrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(item: 0, section: section))
        
        attrs.frame = frame
        attrs.zIndex = section + zIndexOffset
        attrs.alpha = 1
        
        // TODO: This does hide some headers that would not collide because the previous header is already hidden
        if section > 0 && self.baseHeaderLayoutAttributes(for: section - 1).frame.intersects(frame){
            attrs.isHidden = true
        }
        
        return attrs
    }
    
    private func baseHeaderLayoutAttributes(for section: Int) -> UICollectionViewLayoutAttributes {
        while section >= self.baseHeaderAttributesCache.endIndex {
            self.baseHeaderAttributesCache.append(self.makeBaseHeaderLayoutAttributes(for: self.baseHeaderAttributesCache.endIndex))
        }
        
        return self.baseHeaderAttributesCache[section].copy() as! UICollectionViewLayoutAttributes
    }
    
    func headerLayoutAttributes(for section: Int) -> UICollectionViewLayoutAttributes {
        let attrs = self.baseHeaderLayoutAttributes(for: section)
        let visibleBounds = self.visibleBoundsProvider()
        
        attrs.frame.origin.x = visibleBounds.minX
        if attrs.frame.origin.y < visibleBounds.minY {
            attrs.frame.origin.y = visibleBounds.minY
            
            if section < self.numberOfSections - 1 {
                let nextVisibleHeaderAttrs = self.lazyBaseHeaderAttributes[section+1..<self.numberOfSections].first {
                    !$0.isHidden
                }
                if let nextVisibleHeaderAttrs = nextVisibleHeaderAttrs, attrs.frame.maxY > nextVisibleHeaderAttrs.frame.minY {
                    attrs.frame.origin.y = min(attrs.frame.minY, nextVisibleHeaderAttrs.frame.minY)
                    let overlapRatio = (attrs.frame.maxY - nextVisibleHeaderAttrs.frame.minY)/attrs.frame.height
                    attrs.alpha = 1 - max(0, min(1, overlapRatio))
                    
                }
            }
        }
        
        return attrs
    }
    
    func headerLayoutAttributes(in rect: CGRect) -> [UICollectionViewLayoutAttributes] {
        let lazyAttrs = (0..<self.numberOfSections).lazy.map { section in
            self.headerLayoutAttributes(for: section)
        }
        
        let firstMatchIndex = lazyAttrs.binarySearch { attrs in
            if attrs.frame.minY > rect.maxY {
                return .before
            } else if attrs.frame.maxY < rect.minY {
                return .after
            }
            return .equal
        }
        
        guard let firstMatchIndex = firstMatchIndex else {
            return []
        }
        
        var result: [UICollectionViewLayoutAttributes] = []
        
        for attrs in lazyAttrs[..<firstMatchIndex].reversed() {
            guard attrs.frame.maxY >= rect.minY else { break }
            result.insert(attrs, at: 0)
        }
        
        for attrs in lazyAttrs[firstMatchIndex...] {
            guard attrs.frame.minY <= rect.maxY else { break }
            result.append(attrs)
        }
        
        return result
    }
    
    func indexPathsToInvalidate(in rect: CGRect) -> [IndexPath] {
        var indexPaths = self.headerLayoutAttributes(in: rect).map(\.indexPath)
        
        if let firstSection = indexPaths.first?.section, firstSection > 0 {
            let newFirstIndexPath = (0..<firstSection).reversed().lazy.map {
                self.baseHeaderLayoutAttributes(for: $0)
            }.first {
                !$0.isHidden
            }?.indexPath
            
            if let newFirstIndexPath = newFirstIndexPath {
                indexPaths.insert(newFirstIndexPath, at: 0)
            }
        }
        
        return indexPaths
    }
}
