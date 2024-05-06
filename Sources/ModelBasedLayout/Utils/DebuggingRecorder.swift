//
//  DebuggingRecorder.swift
//
//
//  Created by Matteo Ludwig on 06.05.24.
//

import Foundation
import UIKit

extension UICollectionViewUpdateItem.Action: Codable {
}


public class DebuggingRecorder {
    public var entries: [Entry] = []
    internal var playbackIndex: Int = 0
    
    public init() {
        self.entries = []
    }
    
    public func record(_ entry: Entry) {
        self.entries.append(entry)
    }
    
    public func encodedEntries() throws -> Data {
        return try JSONEncoder().encode(entries)
    }
    
    internal func nextEntry() -> Entry? {
        guard self.playbackIndex < self.entries.endIndex else { return nil }
        defer { self.playbackIndex += 1}
        return self.entries[self.playbackIndex]
    }
}

extension DebuggingRecorder {
    public struct UpdateItem: Equatable, Codable {
        var indexPathBeforeUpdate: IndexPair?
        var indexPathAfterUpdate: IndexPair?
        var updateAction: UICollectionViewUpdateItem.Action

        init(from updateItem: UICollectionViewUpdateItem) {
            self.indexPathBeforeUpdate = updateItem.indexPathBeforeUpdate.map { IndexPair($0) }
            self.indexPathAfterUpdate = updateItem.indexPathAfterUpdate.map { IndexPair($0) }
            self.updateAction = updateItem.updateAction
        }
    }
    
    public struct InvalidationContext: Equatable, Codable {
        var invalidateEverything: Bool = false
        var invalidateDataSourceCounts: Bool = false
        var invalidatedItemIndexPaths: [IndexPair] = []
        var invalidatedSupplementaryIndexPaths: [String: [IndexPair]] = [:]
        var contentOffsetAdjustment: CGPoint = .zero
        var contentSizeAdjustment: CGSize = .zero

        init(from invalidationContext: UICollectionViewLayoutInvalidationContext) {
            self.invalidateEverything = invalidationContext.invalidateEverything
            self.invalidateDataSourceCounts = invalidationContext.invalidateDataSourceCounts
            self.invalidatedItemIndexPaths = invalidationContext.invalidatedItemIndexPaths?.map { IndexPair($0) } ?? []
            self.invalidatedSupplementaryIndexPaths = invalidationContext.invalidatedSupplementaryIndexPaths?.reduce(into: [:]) { result, element in
                result[element.key] = element.value.map { IndexPair($0) }
            } ?? [:]
            self.contentOffsetAdjustment = invalidationContext.contentOffsetAdjustment
            self.contentSizeAdjustment = invalidationContext.contentSizeAdjustment
        }
    }
    public enum Entry: Equatable, Codable {
        case dataSourceCountsProvider(DataSourceCounts)
        case geometryInfoProvider(GeometryInfo)
        case boundsProvider(BoundsInfo)
        
        case collectionViewContentSize(result: CGSize)
        
        case prepare
        case prepareForAnimatedBoundsChange(oldBound: CGRect)
        case finalizeAnimatedBoundsChange
        case prepareForCollectionViewUpdates(updateItems: [UpdateItem])
        case finalizeCollectionViewUpdates
        
        case invalidateModel
        
        case invalidateLayout
        case invalidateLayoutWith(context: InvalidationContext)
        case invalidationContextForBoundsChange(newBounds: CGRect, result: InvalidationContext)
        
        case shouldInvalidateLayoutForBoundsChange(newBounds: CGRect, result: Bool)
        
        case shouldInvalidateLayoutForPreferredLayoutAttributes(preferredAttributes: LayoutAttributes, originalAttributes: LayoutAttributes, result: Bool)
        case invalidationContextForPreferredLayoutAttributes(preferredAttributes: LayoutAttributes, originalAttributes: LayoutAttributes, result: InvalidationContext)
        
        case targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, velocity: CGPoint?, result: CGPoint)
        
        case layoutAttributesForElements(rect: CGRect, result: [LayoutAttributes]?)

        case initialLayoutAttributesForAppearingItem(indexPath: IndexPair, result: LayoutAttributes?)
        case layoutAttributesForItem(indexPath: IndexPair, result: LayoutAttributes?)
        case finalLayoutAttributesForDisappearingItem(indexPath: IndexPair, result: LayoutAttributes?)
        case initialLayoutAttributesForAppearingSupplementaryElement(elementKind: String, indexPath: IndexPair, result: LayoutAttributes?)
        case layoutAttributesForSupplementaryView(elementKind: String, indexPath: IndexPair, result: LayoutAttributes?)
        case finalLayoutAttributesForDisappearingSupplementaryElement(elementKind: String, indexPath: IndexPair, result: LayoutAttributes?)

        
        public static func == (lhs: DebuggingRecorder.Entry, rhs: DebuggingRecorder.Entry) -> Bool {
            switch (lhs, rhs) {
            case (.collectionViewContentSize(let result1), .collectionViewContentSize(let result2)):
                return result1 == result2
                
            case (.prepare, .prepare):
                return true
                
            case (.prepareForAnimatedBoundsChange(let oldBound1), .prepareForAnimatedBoundsChange(let oldBound2)):
                return oldBound1 == oldBound2
                
            case (.finalizeAnimatedBoundsChange, .finalizeAnimatedBoundsChange):
                return true
                
            case (.prepareForCollectionViewUpdates(let updateItems1), .prepareForCollectionViewUpdates(let updateItems2)):
                return updateItems1 == updateItems2
                
            case (.finalizeCollectionViewUpdates, .finalizeCollectionViewUpdates):
                return true
                
            case (.invalidateModel, .invalidateModel):
                return true
                
            case (.invalidateLayout, .invalidateLayout):
                return true
                
            case (.invalidateLayoutWith(let context1), .invalidateLayoutWith(let context2)):
                return context1 == context2
                
            case (.invalidationContextForBoundsChange(let newBounds1, let result1), .invalidationContextForBoundsChange(let newBounds2, let result2)):
                return newBounds1 == newBounds2 && result1 == result2
                
            case (.shouldInvalidateLayoutForBoundsChange(let newBounds1, let result1), .shouldInvalidateLayoutForBoundsChange(let newBounds2, let result2)):
                return newBounds1 == newBounds2 && result1 == result2
                
            case (.shouldInvalidateLayoutForPreferredLayoutAttributes(let preferredAttributes1, let originalAttributes1, let result1), .shouldInvalidateLayoutForPreferredLayoutAttributes(let preferredAttributes2, let originalAttributes2, let result2)):
                return preferredAttributes1 == preferredAttributes2 && originalAttributes1 == originalAttributes2 && result1 == result2
                
            case (.invalidationContextForPreferredLayoutAttributes(let preferredAttributes1, let originalAttributes1, let result1), .invalidationContextForPreferredLayoutAttributes(let preferredAttributes2, let originalAttributes2, let result2)):
                return preferredAttributes1 == preferredAttributes2 && originalAttributes1 == originalAttributes2 && result1 == result2
                
            case (.targetContentOffsetForProposedContentOffset(let proposedContentOffset1, let velocity1, let result1), .targetContentOffsetForProposedContentOffset(let proposedContentOffset2, let velocity2, let result2)):
                return proposedContentOffset1 == proposedContentOffset2 && velocity1 == velocity2 && result1 == result2
                
            case (.layoutAttributesForElements(let rect1, let result1), .layoutAttributesForElements(let rect2, let result2)):
                return rect1 == rect2 && result1 == result2
                
            case (.initialLayoutAttributesForAppearingItem(let indexPath1, let result1), .initialLayoutAttributesForAppearingItem(let indexPath2, let result2)):
                return indexPath1 == indexPath2 && result1 == result2
                
            case (.layoutAttributesForItem(let indexPath1, let result1), .layoutAttributesForItem(let indexPath2, let result2)):
                return indexPath1 == indexPath2 && result1 == result2
                
            case (.finalLayoutAttributesForDisappearingItem(let indexPath1, let result1), .finalLayoutAttributesForDisappearingItem(let indexPath2, let result2)):
                return indexPath1 == indexPath2 && result1 == result2
                
            case (.initialLayoutAttributesForAppearingSupplementaryElement(let elementKind1, let indexPath1, let result1), .initialLayoutAttributesForAppearingSupplementaryElement(let elementKind2, let indexPath2, let result2)):
                return elementKind1 == elementKind2 && indexPath1 == indexPath2 && result1 == result2
                
            case (.layoutAttributesForSupplementaryView(let elementKind1, let indexPath1, let result1), .layoutAttributesForSupplementaryView(let elementKind2, let indexPath2, let result2)):
                return elementKind1 == elementKind2 && indexPath1 == indexPath2 && result1 == result2
                
            case (.finalLayoutAttributesForDisappearingSupplementaryElement(let elementKind1, let indexPath1, let result1), .finalLayoutAttributesForDisappearingSupplementaryElement(let elementKind2, let indexPath2, let result2)):
                return elementKind1 == elementKind2 && indexPath1 == indexPath2 && result1 == result2
                
            default:
                return false
            }
        }
    }
}
