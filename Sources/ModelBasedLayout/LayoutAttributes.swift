//
//  LayoutAttributes.swift
//  ModelBasedCollectionView
//
//  Created by Matteo Ludwig on 18.07.23.
//

import UIKit

private extension CATransform3D {
    static var identity: CATransform3D = .init(m11: 1, m12: 0, m13: 0, m14: 0, m21: 0, m22: 1, m23: 0, m24: 0, m31: 0, m32: 0, m33: 1, m34: 0, m41: 0, m42: 0, m43: 0, m44: 1)
}


struct LayoutAttributes {
    let indexPath: IndexPath
    
    let elementCategory: UICollectionView.ElementCategory
    let elementKind: String?
   
    var frame: CGRect
    var zIndex: Int
    
    var alpha: CGFloat
    var isHidden: Bool
    
    var transform: CGAffineTransform
    var transform3D: CATransform3D
    
    var center: CGPoint {
        get {
            CGPoint(x: frame.midX, y: frame.midY)
        }
        set {
            frame.origin =  CGPoint(x: newValue.x - size.width/2,
                                    y: newValue.y - size.height/2)
        }
    }
    
    var size: CGSize {
        get {
            frame.size
        }
        set {
            frame.size = newValue
        }
    }
    init(forCellAt indexPath: IndexPath,
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
    }
    
    init(forSupplementaryViewAt indexPath: IndexPath, elementKind: String?,
         frame: CGRect = .zero, zIndex: Int = 0,
         alpha: CGFloat = 1, isHidden: Bool = false,
         transform: CGAffineTransform = .identity, transform3D: CATransform3D = .init()) {
        self.indexPath = indexPath
        self.elementCategory = .supplementaryView
        self.elementKind = elementKind
        self.frame = frame
        self.zIndex = zIndex
        self.alpha = alpha
        self.isHidden = isHidden
        self.transform = transform
        self.transform3D = transform3D
    }
    
    init(forDecorativeViewAt indexPath: IndexPath, elementKind: String?,
         frame: CGRect = .zero, zIndex: Int = 0,
         alpha: CGFloat = 1, isHidden: Bool = false,
         transform: CGAffineTransform = .identity, transform3D: CATransform3D = .init()) {
        self.indexPath = indexPath
        self.elementCategory = .decorationView
        self.elementKind = elementKind
        self.frame = frame
        self.zIndex = zIndex
        self.alpha = alpha
        self.isHidden = isHidden
        self.transform = transform
        self.transform3D = transform3D
    }
    
    init(_ collectionViewLayoutAttributes: UICollectionViewLayoutAttributes) {
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
    
    func forLayout() -> UICollectionViewLayoutAttributes {
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
