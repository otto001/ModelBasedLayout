//
//  LayoutAttributes.swift
//  ModelBasedLayout
//
//  Created by Matteo Ludwig on 18.07.23.
//

import UIKit


public struct LayoutAttributes {
    // MARK: Element
    public private(set) var element: Element
    var indexPair: IndexPair { element.indexPair }
    var elementKind: ElementKind { element.elementKind }
    
    
    // MARK: Geometry
    private var _frame: CGRect
    public var transform: CGAffineTransform
    
    public var frame: CGRect {
        get {
            return _frame.applying(transform)
        }
        set {
            _frame = newValue
        }
    }
    
    public var bounds: CGRect {
        get {
            CGRect(origin: .zero, size: _frame.size)
        }
        set {
            assert(newValue.origin == .zero, "LayoutAttribute bounds must have their origin equal (0, 0).")
            _frame.size = newValue.size
        }
    }
    
    // MARK: Visuals
    public var zIndex: Int
    public var alpha: CGFloat
    public var isHidden: Bool
    
    
    // MARK: StickyAttributes
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
    
    // MARK: Init
    public init(element: Element,
                frame: CGRect = .zero, zIndex: Int = 0,
                alpha: CGFloat = 1, isHidden: Bool = false,
                transform: CGAffineTransform = .identity) {
        self.element = element
        self._frame = frame
        self.zIndex = zIndex
        self.alpha = alpha
        self.isHidden = isHidden
        self.transform = transform
    }
    
    // MARK: from UIKit
    public init(_ collectionViewLayoutAttributes: UICollectionViewLayoutAttributes) {
        self.element = .init(indexPair: .init(collectionViewLayoutAttributes.indexPath), elementKind: .init(from: collectionViewLayoutAttributes))
        
        
        self._frame = collectionViewLayoutAttributes.frame
        self.zIndex = collectionViewLayoutAttributes.zIndex
        
        self.alpha = collectionViewLayoutAttributes.alpha
        self.isHidden = collectionViewLayoutAttributes.isHidden
        
        self.transform = collectionViewLayoutAttributes.transform
        //self.transform3D = collectionViewLayoutAttributes.transform3D
    }
    
    // MARK: to UIKit
    public func forLayout() -> UICollectionViewLayoutAttributes {
        let collectionViewLayoutAttributes: UICollectionViewLayoutAttributes
        
        
        switch self.element.elementKind {
        case .cell:
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forCellWith: element.indexPair.indexPath)
        case .header:
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: element.indexPair.indexPath)
        case .footer:
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: element.indexPair.indexPath)
        case .additionalSupplementaryView(let elementKind):
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: element.indexPair.indexPath)
        case .decorativeView(let elementKind):
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: element.indexPair.indexPath)
        }
        
        collectionViewLayoutAttributes.frame = self._frame
        collectionViewLayoutAttributes.transform = self.transform
        
        
        collectionViewLayoutAttributes.alpha = self.alpha
        collectionViewLayoutAttributes.isHidden = self.isHidden
        collectionViewLayoutAttributes.zIndex = self.zIndex
        
        //collectionViewLayoutAttributes.transform3D = self.transform3D
        
        return collectionViewLayoutAttributes
    }
    
    // MARK: Helpers
    internal func withIndexPair(_ indexPair: IndexPair) -> Self {
        var copy = self
        copy.element.indexPair = indexPair
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
    
    public func offset(by point: CGPoint) -> Self {
        var copy = self
        copy.frame = copy.frame.offsetBy(dx: point.x, dy: point.y)
        return copy
    }
}
