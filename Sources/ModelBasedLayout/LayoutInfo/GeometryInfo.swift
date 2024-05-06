//
//  GeometryInfo.swift
//  
//
//  Created by Matteo Ludwig on 16.08.23.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public struct GeometryInfo: Equatable, Codable {
    
    public var viewSize: CGSize
    public var safeAreaInsets: NativeEdgeInsets
    
    init(viewSize: CGSize, safeAreaInsets: NativeEdgeInsets) {
        self.viewSize = viewSize
        self.safeAreaInsets = safeAreaInsets
    }
    
#if canImport(UIKit)
    init(collectionView: UICollectionView) {
        self.viewSize = collectionView.bounds.size
        self.safeAreaInsets = collectionView.safeAreaInsets
    }
#endif
}
