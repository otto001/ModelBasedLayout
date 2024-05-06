//
//  DataSourceCounts.swift
//  
//
//  Created by Matteo Ludwig on 16.08.23.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public struct DataSourceCounts: Codable {
    public let itemCount: Int
    public let sections: [SectionData]
    
    
    public struct SectionData: Codable {
        public let section: Int
        public let itemCount: Int
        public let firstItemIndex: Int
        
        public var lastItemIndex: Int {
            firstItemIndex + itemCount - 1
        }
        
        public var firstItemIndexPair: IndexPair {
            return IndexPair(item: 0, section: section)
        }
        
        public var lastItemIndexPair: IndexPair {
            return IndexPair(item: itemCount - 1, section: section)
        }
    }
    
    public var numberOfSections: Int {
        sections.count
    }
    
    init(collectionView: NativeCollectionView) {
        
        let sectionCount = collectionView.numberOfSections
        
        var itemCount = 0
        var sections = [SectionData]()
        
        for section in 0..<sectionCount {
            let sectionItemsCount = collectionView.numberOfItems(inSection: section)
            sections.append(SectionData(section: section, itemCount: sectionItemsCount, firstItemIndex: itemCount))
            itemCount += sectionItemsCount
        }

        self.itemCount = itemCount
        self.sections = sections
    }

    
    init(sections sectionCounts: [Int]) {
        var itemCount = 0
        var sections = [SectionData]()
        
        for (section, sectionItemsCount) in sectionCounts.enumerated() {
            sections.append(SectionData(section: section, itemCount: sectionItemsCount, firstItemIndex: itemCount))
            itemCount += sectionItemsCount
        }
        
        self.itemCount = itemCount
        self.sections = sections
    }
    
    public func index(of indexPair: IndexPair) -> Int {
        assert(indexPair.item < self.sections[indexPair.section].itemCount)
        
        return self.sections[indexPair.section].firstItemIndex + indexPair.item
    }
    
    public func indexPair(for index: Int) -> IndexPair {
        assert(index < self.itemCount)
        
        let section = self.sections.binarySearch { section in
            if section.firstItemIndex > index {
                return .afterSearched
            } else if section.lastItemIndex < index {
                return .beforeSearched
            }
            return .equalToSearched
        } ?? sections.endIndex - 1

        return IndexPair(item: index - sections[section].firstItemIndex, section: section)
    }
    
    public func contains(indexPair: IndexPair) -> Bool {
        return sections.indices.contains(indexPair.section) && indexPair.item >= 0 && indexPair.item < sections[indexPair.section].itemCount
    }
    
    public func contains(index: Int) -> Bool {
        return index >= 0 && index < itemCount
    }
    
    public func indexPair(before indexPair: IndexPair) -> IndexPair? {
        if indexPair.item == 0 {
            return indexPair.section > 0 ? IndexPair(item: sections[indexPair.section - 1].itemCount - 1, section: indexPair.section - 1) : nil
        } else {
            return IndexPair(item: indexPair.item - 1, section: indexPair.section)
        }
    }
    
    public func indexPair(after indexPair: IndexPair) -> IndexPair? {
        if indexPair.item == self.sections[indexPair.section].itemCount - 1 {
            return indexPair.section < self.numberOfSections - 1 ? IndexPair(item: 0, section: indexPair.section + 1) : nil
        } else {
            return IndexPair(item: indexPair.item + 1, section: indexPair.section)
        }
    }
    
    public func indexPairs(for range: ClosedRange<Int>) -> [IndexPair] {
        guard self.itemCount > 0 else { return [] }
        
        let startIndex = range.lowerBound.clamp(min: 0, max: self.itemCount-1)
        let endIndex = range.upperBound.clamp(min: 0, max: self.itemCount-1)
        guard endIndex >= startIndex else { return [] }
        
        let firstIndexPair = self.indexPair(for: startIndex)
        let lastIndexPair = self.indexPair(for: endIndex)
        
        let result = Array(unsafeUninitializedCapacity: endIndex - startIndex + 1) { buffer, initializedCount in
            var index = 0
            
            if firstIndexPair.section == lastIndexPair.section {
                for itemIndex in firstIndexPair.item...lastIndexPair.item {
                    buffer[index] = IndexPair(item: itemIndex, section: firstIndexPair.section)
                    index += 1
                }
            } else {
                for itemIndex in firstIndexPair.item...self.sections[firstIndexPair.section].itemCount-1 {
                    buffer[index] = IndexPair(item: itemIndex, section: firstIndexPair.section)
                    index += 1
                }
                
                if firstIndexPair.section+1 <= lastIndexPair.section-1 {
                    for sectionIndex in firstIndexPair.section+1...lastIndexPair.section-1 {
                        let sectionData = self.sections[sectionIndex]
                        for itemIndex in 0...sectionData.itemCount-1 {
                            buffer[index] = IndexPair(item: itemIndex, section: sectionIndex)
                            index += 1
                        }
                    }
                }

                for itemIndex in 0...lastIndexPair.item {
                    buffer[index] = IndexPair(item: itemIndex, section: lastIndexPair.section)
                    index += 1
                }
            }
            
            initializedCount = index
        }

        return result
    }
    
    public func indexPairs(for range: Range<Int>) -> [IndexPair] {
        return indexPairs(for: range.lowerBound...range.upperBound-1)
    }
}


extension DataSourceCounts: Equatable {
    public static func == (lhs: DataSourceCounts, rhs: DataSourceCounts) -> Bool {
        guard lhs.itemCount == rhs.itemCount && lhs.sections.count == rhs.sections.count else { return false }
        
        for i in 0..<lhs.sections.count {
            guard lhs.sections[i].itemCount == rhs.sections[i].itemCount else { return false }
        }
        
        return true
    }
}
