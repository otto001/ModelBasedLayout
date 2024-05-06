//
//  Element.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public struct Element: Hashable, Equatable, Codable {
    public var indexPair: IndexPair
    public var elementKind: ElementKind
    
    init(indexPair: IndexPair, elementKind: ElementKind) {
        self.indexPair = indexPair
        self.elementKind = elementKind
    }
    
#if canImport(UIKit)
    init(_ collectionViewLayoutAttributes: UICollectionViewLayoutAttributes) {
        self.elementKind = ElementKind(from: collectionViewLayoutAttributes)
        self.indexPair = IndexPair(collectionViewLayoutAttributes.indexPath)
    }
#endif
    
    public static func cell(_ indexPair: IndexPair) -> Self {
        return Element(indexPair: indexPair, elementKind: .cell)
    }
    
    public static func header(section: Int) -> Self {
        return Element(indexPair: IndexPair(item: 0, section: section), elementKind: .header)
    }
    
    public static func footer(section: Int) -> Self {
        return Element(indexPair: IndexPair(item: 0, section: section), elementKind: .footer)
    }
    
    public static func supplementaryView(ofKind elementKind: String, at indexPair: IndexPair) -> Self {
        return Element(indexPair: indexPair, elementKind: .init(supplementaryOfKind: elementKind))
    }
}
