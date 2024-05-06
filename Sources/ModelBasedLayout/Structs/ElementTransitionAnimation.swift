//
//  ElementTransitionAnimation.swift
//  
//
//  Created by Matteo Ludwig on 01.08.23.
//

import Foundation

/// The animation type of an element transition that will be applied if an element is inserted, deleted, or reloaded. Options are `none`, `opacity`, and `custom`. If `none` is selected, no animation will be applied. If `opacity` is selected, the element will fade in or out. If `custom` is selected, the layout model is responsible for providing a custom animation.
public enum ElementTransitionAnimation {
    /// No animation will be applied. Elements will appear or disappear instantly.
    case none
    /// The element will fade in or out using an opacity animation.
    case opacity
    /// A custom animation will be applied. The layout model is responsible for providing the animation.
    case custom
}
