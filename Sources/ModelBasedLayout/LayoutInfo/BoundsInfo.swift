//
//  BoundsInfo.swift
//  
//
//  Created by Matteo Ludwig on 23.09.23.
//

import Foundation


public struct BoundsInfo: Codable {
    public var bounds: CGRect
    public var safeAreaInsets: NativeEdgeInsets
    public var adjustedContentInset: NativeEdgeInsets
    
    public var safeAreaBounds: CGRect {
        bounds.inset(by: safeAreaInsets)
    }
    
    public init(bounds: CGRect, safeAreaInsets: NativeEdgeInsets, adjustedContentInset: NativeEdgeInsets) {
        self.bounds = bounds
        self.safeAreaInsets = safeAreaInsets
        self.adjustedContentInset = adjustedContentInset
    }
}

extension BoundsInfo: Equatable {
    
}
