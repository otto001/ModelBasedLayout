//
//  Item.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import Foundation


public enum Item {
    case cell(IndexPath)
    case header(section: Int)
    case additionalSupplementaryView(elementKind: String, indexPath: IndexPath)
    //case footer(section: Int)
}
