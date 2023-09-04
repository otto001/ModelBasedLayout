//
//  Element.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import UIKit


public struct Element: Hashable, Equatable {
    public var indexPair: IndexPair
    public var elementKind: ElementKind
//    
//    
//    init(supplementaryOfKind elementKind: String, indexPair: IndexPair) {
//        self.indexPair = indexPair
//        
//    }
    
    public static func cell(_ indexPair: IndexPair) -> Self {
        return Element(indexPair: indexPair, elementKind: .cell)
    }
    
    public static func header(section: Int) -> Self {
        return Element(indexPair: IndexPair(item: 0, section: section), elementKind: .header)
    }
    
    public static func footer(section: Int) -> Self {
        return Element(indexPair: IndexPair(item: 0, section: section), elementKind: .footer)
    }
    
    public static func additionalSupplementaryView(ofKind elementKind: String, at indexPair: IndexPair) -> Self {
        return Element(indexPair: indexPair, elementKind: .additionalSupplementaryView(elementKind))
    }
}
