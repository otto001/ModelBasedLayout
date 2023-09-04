//
//  LayoutAttributes.swift
//  ModelBasedCollectionView
//
//  Created by Matteo Ludwig on 18.07.23.
//

import UIKit

public extension CATransform3D {
    static var identity: CATransform3D = .init(m11: 1, m12: 0, m13: 0, m14: 0, m21: 0, m22: 1, m23: 0, m24: 0, m31: 0, m32: 0, m33: 1, m34: 0, m41: 0, m42: 0, m43: 0, m44: 1)
}



public struct LayoutAttributes {
    public private(set) var indexPair: IndexPair
    
    public let elementKind: ElementKind
   
    public var frame: CGRect
    public var zIndex: Int
    
    public var alpha: CGFloat
    public var isHidden: Bool
    
    public var transform: CGAffineTransform
    
    // Sticky
    public var stickyAttributes: StickyAttributes?
    internal var extendedStickyBounds: CGRect? {
        if let stickyAttributes = stickyAttributes {
            switch stickyAttributes.boundingBehaviour {
            case .push:
                return stickyAttributes.stickyBounds
            case .fade:
                return stickyAttributes.stickyBounds.insetBy(dx: -frame.width, dy: -frame.height)
            }
            
        }
        return nil
    }
    public var isSticky: Bool {
        (stickyAttributes?.stickyBounds ?? .none) != .none
    }
    
    public var center: CGPoint {
        get {
            CGPoint(x: frame.midX, y: frame.midY)
        }
        set {
            frame.origin =  CGPoint(x: newValue.x - size.width/2,
                                    y: newValue.y - size.height/2)
        }
    }
    
    public var size: CGSize {
        get {
            frame.size
        }
        set {
            frame.size = newValue
        }
    }
    
    public init(indexPair: IndexPair,
                elementKind: ElementKind,
         frame: CGRect = .zero, zIndex: Int = 0,
         alpha: CGFloat = 1, isHidden: Bool = false,
         transform: CGAffineTransform = .identity) {
        self.indexPair = indexPair
        self.elementKind = elementKind
        self.frame = frame
        self.zIndex = zIndex
        self.alpha = alpha
        self.isHidden = isHidden
        self.transform = transform
    }
    
    public init(_ collectionViewLayoutAttributes: UICollectionViewLayoutAttributes) {
        self.indexPair = .init(collectionViewLayoutAttributes.indexPath)

        self.elementKind = .init(from: collectionViewLayoutAttributes)

        self.frame = collectionViewLayoutAttributes.frame
        self.zIndex = collectionViewLayoutAttributes.zIndex

        self.alpha = collectionViewLayoutAttributes.alpha
        self.isHidden = collectionViewLayoutAttributes.isHidden

        self.transform = collectionViewLayoutAttributes.transform
        //self.transform3D = collectionViewLayoutAttributes.transform3D
    }
    
    public func forLayout() -> UICollectionViewLayoutAttributes {
        let collectionViewLayoutAttributes: UICollectionViewLayoutAttributes
        
        
        switch self.elementKind {
        case .cell:
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPair.indexPath)
        case .header:
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: indexPair.indexPath)
        case .footer:
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: indexPair.indexPath)
        case .additionalSupplementaryView(let elementKind):
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPair.indexPath)
        case .decorativeView(let elementKind):
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPair.indexPath)
        }
        
        collectionViewLayoutAttributes.frame = self.frame
        collectionViewLayoutAttributes.zIndex = self.zIndex
        
        collectionViewLayoutAttributes.alpha = self.alpha
        collectionViewLayoutAttributes.isHidden = self.isHidden
        
        collectionViewLayoutAttributes.transform = self.transform
        //collectionViewLayoutAttributes.transform3D = self.transform3D
        
        return collectionViewLayoutAttributes
    }
    
    internal func withIndexPair(_ indexPair: IndexPair) -> Self {
        var copy = self
        copy.indexPair = indexPair
        return copy
    }
    
    public func with(alpha: CGFloat) -> Self {
        var copy = self
        copy.alpha = alpha
        return copy
    }
    
    public func isVisible(in rect: CGRect) -> Bool {
        if let extendedStickyBounds = extendedStickyBounds {
            return extendedStickyBounds.intersects(rect)
        }
        return frame.intersects(rect)
    }
}
