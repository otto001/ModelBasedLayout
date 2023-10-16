//
//  BoundsController.swift
//  
//
//  Created by Matteo Ludwig on 13.09.23.
//

import UIKit


class BoundsController {
    
    private var boundsInfoProvider: () -> BoundsInfo
    
    private(set) var boundsInfo: BoundsInfo = .init(bounds: .zero, safeAreaInsets: .zero, adjustedContentInset: .zero)
    
    private var valid: Bool = false
    private(set) var frozen: Bool = false
    
    var bounds: CGRect {
        self.updateBoundsIfNeeded()
        return self.boundsInfo.bounds
    }
    
    var safeAreaBounds: CGRect {
        self.updateBoundsIfNeeded()
        return self.boundsInfo.safeAreaBounds
    }
    
    init(boundsInfoProvider: @escaping () -> BoundsInfo) {
        self.boundsInfoProvider = boundsInfoProvider
        self.updateBoundsIfNeeded()
    }
    
    func invalidate() {
        self.valid = false
    }
    
    func freeze() {
        self.frozen = true
    }
    
    func unfreeze() {
        self.frozen = false
    }
    
    func updateBoundsIfNeeded() {
        guard !self.valid && !self.frozen else { return }
        
        let newBoundsInfo = self.boundsInfoProvider()
        
        self.boundsInfo = newBoundsInfo
        self.valid = true
    }
    
    func setTargetContentOffset(target contentOffset: CGPoint) {
        self.boundsInfo.bounds = CGRect(origin: contentOffset, size: self.boundsInfo.bounds.size)
        self.valid = true
    }
    
}
