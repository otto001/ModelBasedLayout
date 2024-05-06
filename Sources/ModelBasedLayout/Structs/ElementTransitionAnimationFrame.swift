//
//  ElementTransitionAnimationFrame.swift
//  
//
//  Created by Matteo Ludwig on 20.09.23.
//

import Foundation


/// An animation frame for an element transition. Used for custom element transition animations. Options are `initial`, `initialForReload`, `final`, and `finalForReload`.
public enum ElementTransitionAnimationFrame {
    /// The frame before the transition.
    case initial
    /// The frame before the transition for a reload.
    case initialForReload
    /// The frame after the transition.
    case final
    /// The frame after the transition for a reload.
    case finalForReload
    
    /// A convenience method initialize either an initial or initialForReload frame.
    static func initial(reload: Bool) -> ElementTransitionAnimationFrame {
        reload ? .initialForReload : .initial
    }
    
    /// A convenience method initialize either a final or finalForReload frame.
    static func final(reload: Bool) -> ElementTransitionAnimationFrame {
        reload ? .finalForReload : .final
    }
}
