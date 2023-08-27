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
    public let indexPath: IndexPath
    
    public let elementCategory: UICollectionView.ElementCategory
    public let elementKind: String?
   
    public var frame: CGRect
    public var zIndex: Int
    
    public var alpha: CGFloat
    public var isHidden: Bool
    
    public var transform: CGAffineTransform
    public var transform3D: CATransform3D
    
//    public var stickyEdges: Edges {
//        didSet {
//            assert(stickyEdges == .none || elementCategory == .supplementaryView)
//        }
//    }
    
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
    
    public init(forCellAt indexPath: IndexPath,
         frame: CGRect = .zero, zIndex: Int = 0,
         alpha: CGFloat = 1, isHidden: Bool = false,
         transform: CGAffineTransform = .identity, transform3D: CATransform3D = .identity) {
        self.indexPath = indexPath
        self.elementCategory = .cell
        self.elementKind = nil
        self.frame = frame
        self.zIndex = zIndex
        self.alpha = alpha
        self.isHidden = isHidden
        self.transform = transform
        self.transform3D = transform3D
       // self.stickyEdges = .none
    }
    
    public init(forSupplementaryViewAt indexPath: IndexPath, elementKind: String?,
         frame: CGRect = .zero, zIndex: Int = 0,
         alpha: CGFloat = 1, isHidden: Bool = false,
         transform: CGAffineTransform = .identity, transform3D: CATransform3D = .identity,
         stickyEdges: Edges = .none) {
        self.indexPath = indexPath
        self.elementCategory = .supplementaryView
        self.elementKind = elementKind
        self.frame = frame
        self.zIndex = zIndex
        self.alpha = alpha
        self.isHidden = isHidden
        self.transform = transform
        self.transform3D = transform3D
        //self.stickyEdges = stickyEdges
    }
    
    public init(forDecorativeViewAt indexPath: IndexPath, elementKind: String?,
         frame: CGRect = .zero, zIndex: Int = 0,
         alpha: CGFloat = 1, isHidden: Bool = false,
         transform: CGAffineTransform = .identity, transform3D: CATransform3D = .identity) {
        self.indexPath = indexPath
        self.elementCategory = .decorationView
        self.elementKind = elementKind
        self.frame = frame
        self.zIndex = zIndex
        self.alpha = alpha
        self.isHidden = isHidden
        self.transform = transform
        self.transform3D = transform3D
        //self.stickyEdges = .none
    }
    
    public init(_ collectionViewLayoutAttributes: UICollectionViewLayoutAttributes) {
        self.indexPath = collectionViewLayoutAttributes.indexPath

        self.elementCategory = collectionViewLayoutAttributes.representedElementCategory
        self.elementKind = collectionViewLayoutAttributes.representedElementKind

        self.frame = collectionViewLayoutAttributes.frame
        self.zIndex = collectionViewLayoutAttributes.zIndex

        self.alpha = collectionViewLayoutAttributes.alpha
        self.isHidden = collectionViewLayoutAttributes.isHidden

        self.transform = collectionViewLayoutAttributes.transform
        self.transform3D = collectionViewLayoutAttributes.transform3D
    }
    
    public func forLayout() -> UICollectionViewLayoutAttributes {
        let collectionViewLayoutAttributes: UICollectionViewLayoutAttributes
        
        switch self.elementCategory {
        case .cell:
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        case .supplementaryView:
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind!, with: indexPath)
        case .decorationView:
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind!, with: indexPath)
        @unknown default:
            fatalError("Unsupported element Category \"\(self.elementCategory)\"")
        }
        
        collectionViewLayoutAttributes.frame = self.frame
        collectionViewLayoutAttributes.zIndex = self.zIndex
        
        collectionViewLayoutAttributes.alpha = self.alpha
        collectionViewLayoutAttributes.isHidden = self.isHidden
        
        collectionViewLayoutAttributes.transform = self.transform
        collectionViewLayoutAttributes.transform3D = self.transform3D
        
        return collectionViewLayoutAttributes
    }
}
