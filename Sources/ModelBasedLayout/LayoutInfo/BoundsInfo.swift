//
//  BoundsInfo.swift
//  
//
//  Created by Matteo Ludwig on 23.09.23.
//

import UIKit


public struct BoundsInfo {
    public var bounds: CGRect
    public var safeAreaInsets: UIEdgeInsets
    public var adjustedContentInset: UIEdgeInsets
    
    public var safeAreaBounds: CGRect {
        bounds.inset(by: safeAreaInsets)
    }
    
    public init(bounds: CGRect, safeAreaInsets: UIEdgeInsets, adjustedContentInset: UIEdgeInsets) {
        self.bounds = bounds
        self.safeAreaInsets = safeAreaInsets
        self.adjustedContentInset = adjustedContentInset
    }
}
