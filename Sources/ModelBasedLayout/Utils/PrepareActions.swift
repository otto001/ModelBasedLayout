//
//  PrepareActions.swift
//  
//
//  Created by Matteo Ludwig on 01.08.23.
//

import Foundation


struct PrepareActions: OptionSet {
    let rawValue: UInt
    
    static let replaceModel = PrepareActions(rawValue: 1 << 0)
}

