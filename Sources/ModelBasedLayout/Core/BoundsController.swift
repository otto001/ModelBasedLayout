//
//  BoundsController.swift
//  
//
//  Created by Matteo Ludwig on 13.09.23.
//

import UIKit


class BoundsController {
    
    private var boundsInfoProvider: () -> BoundsInfo
    
    private var _boundsInfo: BoundsInfo = .init(bounds: .zero, safeAreaInsets: .zero, adjustedContentInset: .zero)
    
    private var valid: Bool = false
    private(set) var frozen: Bool = false
    
    var boundsInfo: BoundsInfo {
        self.updateBoundsIfNeeded()
        return self._boundsInfo
    }
    
    var bounds: CGRect {
        return self.boundsInfo.bounds
    }
    
    var safeAreaBounds: CGRect {
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
        
        self._boundsInfo = newBoundsInfo
        self.valid = true
    }
    
    func setTargetContentOffset(target contentOffset: CGPoint) {
        self._boundsInfo.bounds = CGRect(origin: contentOffset, size: self._boundsInfo.bounds.size)
        self.valid = true
    }
    
}
