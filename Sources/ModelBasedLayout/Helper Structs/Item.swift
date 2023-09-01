//
//  Item.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import Foundation


public enum Item {
    case cell(IndexPair)
    case header(section: Int)
    case additionalSupplementaryView(elementKind: String, indexPair: IndexPair)
    //case footer(section: Int)
}
