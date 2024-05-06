//
//  Element.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public struct Element: Hashable, Equatable, Codable {
    public var indexPair: IndexPair
    public var elementKind: ElementKind
    
    init(indexPair: IndexPair, elementKind: ElementKind) {
        self.indexPair = indexPair
        self.elementKind = elementKind
    }
    
    init?(_ collectionViewLayoutAttributes: NativeCollectionViewLayoutAttributes) {
#if canImport(UIKit)
        self.indexPair = IndexPair(collectionViewLayoutAttributes.indexPath)
#elseif os(macOS)
        guard let indexPath = collectionViewLayoutAttributes.indexPath else { return nil }
        self.indexPair = IndexPair(indexPath)
#endif
        self.elementKind = ElementKind(from: collectionViewLayoutAttributes)
        
    }
    
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
