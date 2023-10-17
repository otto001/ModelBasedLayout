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
    
    private var viewSize: CGSize
    
    enum State {
        case initializing, valid, invalid, frozen
    }
    private var state: State = .initializing
    
    private var cachedBoundsInfo: BoundsInfo?
    
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
    
    init(boundsInfoProvider: @escaping () -> BoundsInfo, viewSize: CGSize) {
        self.boundsInfoProvider = boundsInfoProvider
        self.viewSize = viewSize
        self.updateBoundsIfNeeded()
    }
    
    func invalidate() {
        guard self.state == .valid else { return }
        self.state = .invalid
    }
    
    func freeze() {
        self.state = .frozen
    }
    
    func updateBoundsIfNeeded() {
        guard self.state == .invalid || self.state == .initializing else { return }
        
        let newBoundsInfo = self.boundsInfoProvider()
        
        guard newBoundsInfo.bounds.size == self.viewSize else {
            if self.state != .initializing {
                if let cachedBoundsInfo = self.cachedBoundsInfo {
                    // If the viewSize changes, the safeAreaInsets may also have changed. If thats the case, we will have cached it earlier and can now rely on that cached value.
                    self._boundsInfo = cachedBoundsInfo
                }
                self.freeze()
            }
            return
        }
        
        if self._boundsInfo.safeAreaInsets != newBoundsInfo.safeAreaInsets {
            // If the viewSize changes, the safeAreaInsets also often change (e.g. if the view is embedded in a UINavigationController).
            // However, this change is done before the viewSize changes, so we have no way of knowing ahead of time if the safeAreaInsets change will be accompanied by a viewSize change, so we cache the old values.
            // This allows us to reset the safeAreaInsets in case the viewSize changes later.
            self.cachedBoundsInfo = self._boundsInfo
        }
        
        self._boundsInfo = newBoundsInfo
        self.state = .valid
    }
    
    func setTargetContentOffset(target contentOffset: CGPoint) {
        self.updateBoundsIfNeeded()
        self._boundsInfo.bounds = CGRect(origin: contentOffset, size: self._boundsInfo.bounds.size)
        self.state = .valid
    }
    
}
