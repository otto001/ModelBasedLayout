//
//  ElementKind.swift
//  
//
//  Created by Matteo Ludwig on 01.09.23.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum ElementKind: Equatable, Hashable, Codable {
    case cell
    case header
    case footer
    case additionalSupplementaryView(String)
    case decorativeView(String)
    
#if canImport(UIKit)
    init(from collectionViewLayoutAttributes: UICollectionViewLayoutAttributes) {
        switch collectionViewLayoutAttributes.representedElementCategory {
        case .cell:
            self = .cell
        case .supplementaryView:
            self = .init(supplementaryOfKind: collectionViewLayoutAttributes.representedElementKind!)
        case .decorationView:
            self = .decorativeView(collectionViewLayoutAttributes.representedElementKind!)
        @unknown default:
            fatalError("Unknown representedElementCategory")
        }
    }

    
    init(supplementaryOfKind elementKind: String) {
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            self = .header
        case UICollectionView.elementKindSectionFooter:
            self = .footer
        default:
            self = .additionalSupplementaryView(elementKind)
        }
    }
    
    var representedElementCategory: UICollectionView.ElementCategory {
        switch self {
        case .cell:
            return .cell
        case .header:
            return .supplementaryView
        case .footer:
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
        case .footer:
            return UICollectionView.elementKindSectionFooter
        case .additionalSupplementaryView(let string):
            return string
        case .decorativeView(let string):
            return string
        }
    }
    
    var isSupplementaryView: Bool {
        return self.representedElementCategory == .supplementaryView
    }
#endif
}
