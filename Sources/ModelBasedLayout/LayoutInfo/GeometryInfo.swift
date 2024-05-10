//
//  GeometryInfo.swift
//  
//
//  Created by Matteo Ludwig on 16.08.23.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public struct GeometryInfo: Equatable {
    
    public var viewSize: CGSize
    public var safeAreaInsets: NativeEdgeInsets
    
    init(viewSize: CGSize, safeAreaInsets: NativeEdgeInsets) {
        self.viewSize = viewSize
        self.safeAreaInsets = safeAreaInsets
    }
    

    init(collectionView: NativeCollectionView) {
#if canImport(UIKit)
        self.viewSize = collectionView.bounds.size
#elseif os(macOS)
        let bounds = collectionView.bounds
        let visibleRect = collectionView.visibleRect
        self.viewSize = CGSize(width: min(bounds.width, visibleRect.width), height: min(bounds.height, visibleRect.height))
#endif
       
        self.safeAreaInsets = collectionView.safeAreaInsets
    }

}
