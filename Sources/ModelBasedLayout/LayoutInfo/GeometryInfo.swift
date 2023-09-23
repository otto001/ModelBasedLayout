//
//  GeometryInfo.swift
//  
//
//  Created by Matteo Ludwig on 16.08.23.
//

import UIKit


public struct GeometryInfo: Equatable {
    
    public var viewSize: CGSize
    public var safeAreaInsets: UIEdgeInsets
    
    init(viewSize: CGSize, safeAreaInsets: UIEdgeInsets) {
        self.viewSize = viewSize
        self.safeAreaInsets = safeAreaInsets
    }
    
    init(collectionView: UICollectionView) {
        self.viewSize = collectionView.bounds.size
        self.safeAreaInsets = collectionView.safeAreaInsets
    }
    
}
