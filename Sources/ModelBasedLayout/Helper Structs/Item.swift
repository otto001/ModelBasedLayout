//
//  Item.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import UIKit


public enum Item {
    case cell(IndexPair)
    case header(section: Int)
    case footer(section: Int)
    case additionalSupplementaryView(elementKind: String, indexPair: IndexPair)
    
    init(supplementaryOfKind elementKind: String, indexPair: IndexPair) {
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            self = .header(section: indexPair.section)
        case UICollectionView.elementKindSectionFooter:
            self = .footer(section: indexPair.section)
        default:
            self = .additionalSupplementaryView(elementKind: elementKind, indexPair: indexPair)
        }
    }
}
