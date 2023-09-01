//
//  DataSourceCounts.swift
//  
//
//  Created by Matteo Ludwig on 16.08.23.
//

import UIKit


public struct DataSourceCounts {
    public let itemsCount: Int
    public let sections: [SectionData]
    
    
    public struct SectionData {
        let section: Int
        let itemCount: Int
        let firstItemIndex: Int
        
        var lastItemIndex: Int {
            firstItemIndex + itemCount - 1
        }
        var firstItemIndexPair: IndexPair {
            return IndexPair(item: 0, section: section)
        }
        var lastItemIndexPair: IndexPair {
            return IndexPair(item: itemCount - 1, section: section)
        }
    }
    
    public var numberOfSections: Int {
        sections.count
    }
    
    init(collectionView: UICollectionView) {
        
        let sectionCount = collectionView.numberOfSections
        
        var itemsCount = 0
        var sections = [SectionData]()
        
        for section in 0..<sectionCount {
            let sectionItemsCount = collectionView.numberOfItems(inSection: section)
            sections.append(SectionData(section: section, itemCount: sectionItemsCount, firstItemIndex: itemsCount))
            itemsCount += sectionItemsCount
        }

        self.itemsCount = itemsCount
        self.sections = sections
    }
    
    init(sections sectionCounts: [Int]) {
        var itemsCount = 0
        var sections = [SectionData]()
        
        for (section, sectionItemsCount) in sectionCounts.enumerated() {
            sections.append(SectionData(section: section, itemCount: sectionItemsCount, firstItemIndex: itemsCount))
            itemsCount += sectionItemsCount
        }
        
        self.itemsCount = itemsCount
        self.sections = sections
    }
    
    public func index(for indexPair: IndexPair) -> Int {
        return self.sections[indexPair.section].firstItemIndex + indexPair.item
    }
    
    public func indexPair(for index: Int) -> IndexPair {
        assert(index < self.itemsCount)
        
        let section = self.sections.binarySearch { section in
            if section.firstItemIndex > index {
                return .after
            } else if section.lastItemIndex < index {
                return .before
            }
            return .equal
        } ?? sections.endIndex - 1

        return IndexPair(item: index - sections[section].firstItemIndex, section: section)
    }
    
    public func indexPair(after indexPair: IndexPair) -> IndexPair? {
        if indexPair.item == self.sections[indexPair.section].itemCount - 1 {
            return indexPair.section < self.numberOfSections - 1 ? IndexPair(item: 0, section: indexPair.section + 1) : nil
        } else {
            return IndexPair(item: indexPair.item + 1, section: indexPair.section)
        }
    }
    
    public func indexPairs(startIndex: Int, endIndex: Int) -> [IndexPair] {
        guard self.itemsCount > 0 else { return [] }
        
        let startIndex = startIndex.clamp(min: 0, max: self.itemsCount-1)
        let endIndex = endIndex.clamp(min: 0, max: self.itemsCount)
        guard endIndex > startIndex else { return [] }
        
        var result = [IndexPair]()
        
        var indexPair = self.indexPair(for: startIndex)
        
        // TODO: This could be optimized a lot by reducing the numer of iterations
        for _ in startIndex...endIndex {
            result.append(indexPair)
            guard let nextIndexPair = self.indexPair(after: indexPair) else {
                break
            }
            indexPair = nextIndexPair
        }
        
        return result
    }
}


extension DataSourceCounts: Equatable {
    public static func == (lhs: DataSourceCounts, rhs: DataSourceCounts) -> Bool {
        guard lhs.itemsCount == rhs.itemsCount && lhs.sections.count == rhs.sections.count else { return false }
        
        for i in 0..<lhs.sections.count {
            guard lhs.sections[i].itemCount == rhs.sections[i].itemCount else { return false }
        }
        
        return true
    }
    
    
}
