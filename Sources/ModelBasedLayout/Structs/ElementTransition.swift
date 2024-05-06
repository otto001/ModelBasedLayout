//
//  ElementTransition.swift
//  
//
//  Created by Matteo Ludwig on 04.09.23.
//

import Foundation


/// The transition type of an element for the steps in a lifecycle of an element. Options are `insertion`, `deletion`, and `reload`.
public enum ElementTransition {
    /// The element is inserted.
    case insertion
    /// The element is deleted.
    case deletion
    /// The element is reloaded.
    case reload
}
