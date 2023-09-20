//
//  BoundsController.swift
//  
//
//  Created by Matteo Ludwig on 13.09.23.
//

import UIKit


class BoundsController {
    
    private var boundsProvider: () -> CGRect
    private(set) var safeAreaInsets: UIEdgeInsets = .zero
    
    private var _bounds: CGRect = .zero {
        didSet {
            self._visibleBounds = CGRect(x: self._bounds.minX + self.safeAreaInsets.left,
                                         y:  self._bounds.minY + self.safeAreaInsets.top,
                                         width:  self._bounds.width - self.safeAreaInsets.left - self.safeAreaInsets.right,
                                         height:  self._bounds.height - self.safeAreaInsets.top - self.safeAreaInsets.bottom)
        }
    }
    private var _visibleBounds: CGRect = .zero
    
    private var valid: Bool = false
    private(set) var frozen: Bool = false
    
    var bounds: CGRect {
        self.updateBoundsIfNeeded()
        return self._bounds
    }
    
    var visibleBounds: CGRect {
        self.updateBoundsIfNeeded()
        return self._visibleBounds
    }
    
    init(boundsProvider: @escaping () -> CGRect, safeAreaInsets: UIEdgeInsets) {
        self.boundsProvider = boundsProvider
        self.safeAreaInsets = safeAreaInsets
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
        
        let newBounds = self.boundsProvider()
        
        guard newBounds.size == self._bounds.size || self._bounds.size == .zero else {
            return
        }
        
        self._bounds = newBounds
        self.valid = true
    }
    
    func setTargetContentOffset(target contentOffset: CGPoint) {
        self._bounds = CGRect(origin: contentOffset, size: self._bounds.size)
        self.valid = true
    }
    
}
