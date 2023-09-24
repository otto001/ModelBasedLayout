//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 13.09.23.
//

import UIKit


public class InvalidationContext: UICollectionViewLayoutInvalidationContext {
    public internal(set) var invalidateGeometryInfo: Bool = false
    public internal(set) var invalidateModel: Bool = false
    public internal(set) var invalidateStickyCache: Bool = false
    
    func invalidateElement(_ element: Element) {
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
    }
}
