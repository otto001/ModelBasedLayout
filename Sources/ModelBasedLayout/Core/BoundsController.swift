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

        guard self.updateBounds(newBoundsInfo.bounds) else { return }

        if self._boundsInfo.safeAreaInsets != newBoundsInfo.safeAreaInsets {
            // If the view hieranchy of the collectionView is transitioning to another size (e.g. on device rotation), often times multiple layout passes are performed.
            // E.g.: safeAreaInsets updated -> layout pass -> viewSize updated -> layoutPass
            // This is a problem for us, because we need the initial BoundsInfo and the final BoundsInfo in order to correctly calculate contentOffsetAdjustments etc.
            // However, the BoundsController will only be frozen once the viewSize is update, at which point the safeAreaInsets already have been updated which we would now need to revert.
            // Therefore, we cache the boundsInfo everytime the safeAreaInsets change for the duration of the CATransaction in which they change. This allows us to reset the safeAreaInsets in case the BoundsController is frozen afterwards.
            self.cachedBoundsInfo = self._boundsInfo
            let completionBlock = CATransaction.completionBlock()
            CATransaction.setCompletionBlock { [weak self] in
                self?.cachedBoundsInfo = nil
                completionBlock?()
            }
        }
        
        self._boundsInfo = newBoundsInfo
        self.state = .valid
    }
    
    func updateContentOffset(_ contentOffset: CGPoint) {
        self.updateBoundsIfNeeded()
        
        guard self.state != .frozen else { return }
        
        self._boundsInfo.bounds = CGRect(origin: contentOffset, size: self._boundsInfo.bounds.size)
        self.state = .valid
    }
    
    @discardableResult
    func updateBounds(_ newBounds: CGRect) -> Bool {
        guard newBounds.size == self.viewSize else {
            if self.state != .initializing {
                if let cachedBoundsInfo = self.cachedBoundsInfo {
                    // If the viewSize changes, the safeAreaInsets may also have changed. If thats the case, we will have cached it earlier and can now rely on that cached value.
                    self._boundsInfo = cachedBoundsInfo
                }
                self.freeze()
            }
            return false
        }
        
        self._boundsInfo.bounds = newBounds
        return true
    }
    
}
