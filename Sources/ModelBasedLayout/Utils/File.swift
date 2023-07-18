//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 18.07.23.
//

import Foundation


extension BinaryInteger {
    
    func clamp(min: Self, max: Self) -> Self {
        Swift.max(min, Swift.min(max, self))
    }
}
