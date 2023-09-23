//
//  BoundsInfo.swift
//  
//
//  Created by Matteo Ludwig on 23.09.23.
//

import UIKit


struct BoundsInfo {
    var bounds: CGRect
    var safeAreaInsets: UIEdgeInsets
    var adjustedContentInset: UIEdgeInsets
    
    var safeAreaBounds: CGRect {
        bounds.inset(by: safeAreaInsets)
    }
    
    init(bounds: CGRect, safeAreaInsets: UIEdgeInsets, adjustedContentInset: UIEdgeInsets) {
        self.bounds = bounds
        self.safeAreaInsets = safeAreaInsets
        self.adjustedContentInset = adjustedContentInset
    }
}
