//
//  ElementKind.swift
//  
//
//  Created by Matteo Ludwig on 01.09.23.
//

import UIKit


public enum ElementKind: Equatable, Hashable {
    case cell
    case header
    case additionalSupplementaryView(String)
    case decorativeView(String)
    
    init(from collectionViewLayoutAttributes: UICollectionViewLayoutAttributes) {
        switch collectionViewLayoutAttributes.representedElementCategory {
        case .cell:
            self = .cell
        case .supplementaryView:
            switch collectionViewLayoutAttributes.representedElementKind! {
            case UICollectionView.elementKindSectionHeader:
                self = .header
            default:
                self = .additionalSupplementaryView(collectionViewLayoutAttributes.representedElementKind!)
            }
        case .decorationView:
            self = .decorativeView(collectionViewLayoutAttributes.representedElementKind!)
        @unknown default:
            fatalError("Unknown representedElementCategory")
        }
    }
    
    var representedElementCategory: UICollectionView.ElementCategory {
        switch self {
        case .cell:
            return .cell
        case .header:
            return .supplementaryView
        case .additionalSupplementaryView:
            return .supplementaryView
        case .decorativeView:
            return .decorationView
        }
    }
    
    var representedElementKind: String? {
        switch self {
        case .cell:
            return nil
        case .header:
            return UICollectionView.elementKindSectionHeader
        case .additionalSupplementaryView(let string):
            return string
        case .decorativeView(let string):
            return string
        }
    }
}
