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
    
    private var _bounds: CGRect = .zero
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
        self._visibleBounds = CGRect(x: newBounds.minX + self.safeAreaInsets.left,
                                     y: newBounds.minY + self.safeAreaInsets.top,
                                     width: newBounds.width - self.safeAreaInsets.left - self.safeAreaInsets.right,
                                     height: newBounds.height - self.safeAreaInsets.top - self.safeAreaInsets.bottom)
        self.valid = true
    }
}
