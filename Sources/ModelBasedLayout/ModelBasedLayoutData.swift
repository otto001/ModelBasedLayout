//
//  ModelBasedLayoutData.swift
//  ModelBasedCollectionView
//
//  Created by Matteo Ludwig on 18.07.23.
//

import UIKit



struct ModelBasedLayoutData {
    let collectionViewSize: CGSize
    let itemsCount: Int
    
    let sections: [SectionData]
    
    
    struct SectionData {
        let section: Int
        let itemCount: Int
        let firstItemIndex: Int
        var lastItemIndex: Int {
            firstItemIndex + itemCount - 1
        }
        var firstItemIndexPath: IndexPath {
            return IndexPath(item: 0, section: section)
        }
        var lastItemIndexPath: IndexPath {
            return IndexPath(item: itemCount - 1, section: section)
        }
    }
    
    var numberOfSections: Int {
        sections.count
    }
    
    init(collectionView: UICollectionView, overrideCollectionViewSize: CGSize?) {
        
        let sectionCount = collectionView.numberOfSections
        
        var itemsCount = 0
        var sections = [SectionData]()
        
        for section in 0..<sectionCount {
            let sectionItemsCount = collectionView.numberOfItems(inSection: section)
            sections.append(SectionData(section: section, itemCount: sectionItemsCount, firstItemIndex: itemsCount))
            itemsCount += sectionItemsCount
        }

        self.collectionViewSize = overrideCollectionViewSize ?? collectionView.bounds.size
        self.itemsCount = itemsCount
        self.sections = sections
    }
    
    init(sections sectionCounts: [Int], collectionViewSize: CGSize) {
        var itemsCount = 0
        var sections = [SectionData]()
        
        for (section, sectionItemsCount) in sectionCounts.enumerated() {
            sections.append(SectionData(section: section, itemCount: sectionItemsCount, firstItemIndex: itemsCount))
            itemsCount += sectionItemsCount
        }
        
        self.collectionViewSize = collectionViewSize
        self.itemsCount = itemsCount
        self.sections = sections
    }
    
    func index(for indexPath: IndexPath) -> Int {
        return self.sections[indexPath.section].firstItemIndex + indexPath.item
    }
    
    func indexPath(for index: Int) -> IndexPath {
        assert(index < self.itemsCount)
        
        let section = self.sections.binarySearch { section in
            if section.firstItemIndex > index {
                return .before
            } else if section.lastItemIndex < index {
                return .after
            }
            return .equal
        } ?? sections.endIndex - 1

        return IndexPath(item: index - sections[section].firstItemIndex, section: section)
    }
    
    func indexPath(after indexPath: IndexPath) -> IndexPath? {
        if indexPath.item == self.sections[indexPath.section].itemCount - 1 {
            return indexPath.section < self.numberOfSections - 1 ? IndexPath(item: 0, section: indexPath.section + 1) : nil
        } else {
            return IndexPath(item: indexPath.item + 1, section: indexPath.section)
        }
    }
    
    func indexPaths(startIndex: Int, endIndex: Int) -> [IndexPath] {
        guard self.itemsCount > 0 else { return [] }
        
        let startIndex = startIndex.clamp(min: 0, max: self.itemsCount-1)
        let endIndex = endIndex.clamp(min: 0, max: self.itemsCount)
        guard endIndex > startIndex else { return [] }
        
        var result = [IndexPath]()
        
        var indexPath = self.indexPath(for: startIndex)
        
        // TODO: This could be optimized a lot by reducing the numer of iterations
        for _ in startIndex...endIndex {
            result.append(indexPath)
            guard let nextIndexPath = self.indexPath(after: indexPath) else {
                break
            }
            indexPath = nextIndexPath
        }
        
        return result
    }
}
