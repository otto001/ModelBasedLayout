//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 13.09.23.
//

import UIKit

/// A custom invalidation context that allows to invalidate specific elements and caches.
public class InvalidationContext: UICollectionViewLayoutInvalidationContext {

    /// The geometry info of the layout should be invalidated (e.g., after device rotation/view size change). This will cause the layout to swap the model and recalculate the layout.
    public internal(set) var invalidateGeometryInfo: Bool = false

    /// The model should be invalidated. This will cause the layout to swap the model and recalculate the layout.
    public internal(set) var invalidateModel: Bool = false

    /// The sticky cache should be invalidated. This flag is used in cases where self-sizing cells are used and the sticky cache needs to be recalculated.
    public internal(set) var invalidateStickyCache: Bool = false
    internal var invalidateDynamicElements: Set<Element>? = nil
    
    // TODO: Do we need this?
    internal var userCreatedContext: Bool = true
    
    func invalidateElement(_ element: Element, dynamic: Bool) {
        switch element.elementKind {
        case .cell:
            self.invalidateItems(at: [element.indexPair.indexPath])
        case .header:
            self.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader, at: [element.indexPair.indexPath])
        case .footer:
            self.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionFooter, at: [element.indexPair.indexPath])
        case .additionalSupplementaryView(let elementKind):
            self.invalidateSupplementaryElements(ofKind: elementKind, at: [element.indexPair.indexPath])
        case .decorativeView(let elementKind):
            self.invalidateDecorationElements(ofKind: elementKind, at: [element.indexPair.indexPath])
        }
        
        if dynamic {
            if self.invalidateDynamicElements == nil {
                self.invalidateDynamicElements = .init()
            }
            self.invalidateDynamicElements!.insert(element)
        }
    }
    
    public func invalidateElement(_ element: Element) {
        self.invalidateElement(element, dynamic: false)
    }
}
