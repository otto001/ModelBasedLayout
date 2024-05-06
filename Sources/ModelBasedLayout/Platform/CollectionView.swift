//
//  CollectionView.swift
//  
//
//  Created by Matteo Ludwig on 01.08.23.
//

#if canImport(UIKit)
import UIKit


/// A `UICollectionView` subclass that invalidates its layout when its bounds change. This ensures that the layout is updated when the collection view is resized, for example when the device is rotated. Without this, the layout would not animate smoothly when the collection view is resized.
open class CollectionView: UICollectionView {
    override public func layoutSubviews() {
        // Give the layout a chance to invalidate itself when the bounds change.
        if self.collectionViewLayout.shouldInvalidateLayout(forBoundsChange: self.bounds) {
            let context = self.collectionViewLayout.invalidationContext(forBoundsChange: self.bounds)
            self.collectionViewLayout.invalidateLayout(with: context)
        }
        super.layoutSubviews()
    }
}
#elseif os(macOS)
import AppKit
open class CollectionView: NSCollectionView {}
#endif
