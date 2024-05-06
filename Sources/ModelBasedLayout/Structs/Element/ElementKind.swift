//
//  ElementKind.swift
//  
//
//  Created by Matteo Ludwig on 01.09.23.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public enum ElementKind: Equatable, Hashable, Codable {
    case cell
    case header
    case footer
    case additionalSupplementaryView(String)
    case decorativeView(String)

    init(from collectionViewLayoutAttributes: NativeCollectionViewLayoutAttributes) {
        switch collectionViewLayoutAttributes.representedElementCategory {
#if canImport(UIKit)
        case .cell:
            self = .cell
#elseif os(macOS)
        case .item:
            self = .cell
#endif
            
        case .supplementaryView:
            self = .init(supplementaryOfKind: collectionViewLayoutAttributes.representedElementKind!)
        case .decorationView:
            self = .decorativeView(collectionViewLayoutAttributes.representedElementKind!)
#if os(macOS)
        case .interItemGap:
            fatalError("interItemGaps are not supported")
#endif
        @unknown default:
            fatalError("Unknown representedElementCategory")
        }
    }

    
    init(supplementaryOfKind elementKind: String) {
        switch elementKind {
        case NativeCollectionView.elementKindSectionHeader:
            self = .header
        case NativeCollectionView.elementKindSectionFooter:
            self = .footer
        default:
            self = .additionalSupplementaryView(elementKind)
        }
    }
    
    var representedElementCategory: NativeCollectionViewElementCategory {
        
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
            return NativeCollectionView.elementKindSectionHeader
        case .footer:
            return NativeCollectionView.elementKindSectionFooter
        case .additionalSupplementaryView(let string):
            return string
        case .decorativeView(let string):
            return string
        }
    }
    
    var isSupplementaryView: Bool {
        return self.representedElementCategory == .supplementaryView
    }

}
