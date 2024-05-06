//
//  NativeTypeAliases.swift
//
//
//  Created by Matteo Ludwig on 06.05.24.
//

#if canImport(UIKit)
import UIKit

public typealias NativeCollectionView = UICollectionView
public typealias NativeCollectionViewLayout = UICollectionViewLayout
public typealias NativeCollectionViewTransitionLayout = UICollectionViewTransitionLayout

public typealias NativeCollectionViewUpdateItem = UICollectionViewUpdateItem
public typealias NativeCollectionViewLayoutInvalidationContext = UICollectionViewLayoutInvalidationContext
public typealias NativeCollectionViewLayoutAttributes = UICollectionViewLayoutAttributes
public typealias NativeCollectionViewElementCategory = UICollectionView.ElementCategory

public typealias NativeEdgeInsets = UIEdgeInsets


#elseif os(macOS)
import AppKit

public typealias NativeCollectionView = NSCollectionView
public typealias NativeCollectionViewLayout = NSCollectionViewLayout
public typealias NativeCollectionViewTransitionLayout = NSCollectionViewTransitionLayout
public typealias NativeEdgeInsets = NSEdgeInsets
public typealias NativeCollectionViewUpdateItem = NSCollectionViewUpdateItem
public typealias NativeCollectionViewLayoutInvalidationContext = NSCollectionViewLayoutInvalidationContext
public typealias NativeCollectionViewLayoutAttributes = NSCollectionViewLayoutAttributes
public typealias NativeCollectionViewElementCategory = NSCollectionElementCategory

extension NSEdgeInsets: Equatable {
    public static let zero = NSEdgeInsets()
    public static func == (lhs: NSEdgeInsets, rhs: NSEdgeInsets) -> Bool {
        lhs.top == rhs.top && lhs.left == rhs.left && lhs.bottom == rhs.bottom && lhs.right == rhs.right
    }
}

extension CGRect {
    public func inset(by edgeInsets: NSEdgeInsets) -> CGRect {
        CGRect(x: origin.x + edgeInsets.left, y: origin.y + edgeInsets.top, width: size.width - edgeInsets.left - edgeInsets.right, height: size.height - edgeInsets.top - edgeInsets.bottom)
    }
}

extension NSCollectionElementCategory {
    static let cell: Self = .item
}

extension NSCollectionView {
    var adjustedContentInset: NSEdgeInsets { .zero }
}


#endif
