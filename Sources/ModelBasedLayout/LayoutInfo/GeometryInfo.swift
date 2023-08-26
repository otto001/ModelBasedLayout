//
//  GeometryInfo.swift
//  
//
//  Created by Matteo Ludwig on 16.08.23.
//

import UIKit


public struct GeometryInfo {
    
    public let viewSize: CGSize
    public let adjustedContentInset: UIEdgeInsets
    public let safeAreaInsets: UIEdgeInsets
    
    init(viewSize: CGSize, adjustedContentInset: UIEdgeInsets, safeAreaInsets: UIEdgeInsets) {
        self.viewSize = viewSize
        self.adjustedContentInset = adjustedContentInset
        self.safeAreaInsets = safeAreaInsets
    }
    
    init(collectionView: UICollectionView) {
        self.viewSize = collectionView.bounds.size
        self.adjustedContentInset = collectionView.adjustedContentInset
        self.safeAreaInsets = collectionView.safeAreaInsets
    }
    
}
