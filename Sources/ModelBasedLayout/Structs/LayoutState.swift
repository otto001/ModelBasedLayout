//
//  LayoutState.swift
//  
//
//  Created by Matteo Ludwig on 31.08.23.
//

import Foundation

/// The state of the layout. Options are `beforeUpdate` and `afterUpdate`. If the layout is in the `beforeUpdate` state, the layout is about to be updated. If the layout is in the `afterUpdate` state, the layout has been updated. 
/// - Note: Under normal circumstances, the layout controller should always have a layout in the `afterUpdate` state. It should only have a layout in the `beforeUpdate` state for a very short time while transitioning from one layout model to another (e.g., when the device is rotated).
enum LayoutState {
    /// The layout is before the update.
    case beforeUpdate
    /// The layout is after the update. This is the default state outside of transitions.
    case afterUpdate
}
