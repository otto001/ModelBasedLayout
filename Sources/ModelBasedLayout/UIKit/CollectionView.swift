//
//  CollectionView.swift
//  
//
//  Created by Matteo Ludwig on 01.08.23.
//

import UIKit


public class CollectionView: UICollectionView {
    override public func layoutSubviews() {
        if self.collectionViewLayout.shouldInvalidateLayout(forBoundsChange: self.bounds) {
            let context = self.collectionViewLayout.invalidationContext(forBoundsChange: self.bounds)
            self.collectionViewLayout.invalidateLayout(with: context)
        }
        super.layoutSubviews()
    }
}
