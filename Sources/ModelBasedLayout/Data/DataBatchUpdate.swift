//
//  DataBatchUpdate.swift
//  ModelBasedCollectionView
//
//  Created by Matteo Ludwig on 18.07.23.
//

import UIKit



struct DataBatchUpdate {

    private var indexPairsAfterUpdate: [IndexPair: IndexPair?] = [:]
    private var indexPairsBeforeUpdate: [IndexPair: IndexPair] = [:]
    
    private var sectionIndiciesAfterUpdate: [Int: Int?] = [:]
    
    private var itemReloads: Set<IndexPair> = .init()
    private var sectionReloads: Set<Int> = .init()
    
    private var dataSourceCounts: DataSourceCounts
    
    init(dataSourceCounts: DataSourceCounts, updateItems: [DataUpdate]) {
        self.dataSourceCounts = dataSourceCounts
        
        addUpdateItems(updateItems)
        buildReverseAccessors()
    }
    
    init(dataSourceCounts: DataSourceCounts, updateItems: [UICollectionViewUpdateItem]) {
        self = .init(dataSourceCounts: dataSourceCounts, updateItems: updateItems.compactMap {DataUpdate($0)})
    }
    
    func indexPairAfterUpdate(for indexPair: IndexPair) -> IndexPair? {
        guard sectionIndiciesAfterUpdate[indexPair.section] != nil else { return nil }
        return indexPairsAfterUpdate[indexPair] ?? nil
    }
    
    func indexPairBeforeUpdate(for indexPair: IndexPair) -> IndexPair? {
        return indexPairsBeforeUpdate[indexPair]
    }
    
    func willReload(_ indexPair: IndexPair, state: LayoutState) -> Bool {
        var indexPair = indexPair
        if state == .beforeUpdate {
            guard let indexPairBefore = self.indexPairBeforeUpdate(for: indexPair) else { return false }
            indexPair = indexPairBefore
        }
        return self.sectionReloads.contains(indexPair.section) || self.itemReloads.contains(indexPair)
    }
    
    private mutating func processReloads(_ dataUpdates: inout [DataUpdate]) {
        var result: [DataUpdate] = []
        
        for dataUpdate in dataUpdates {
            switch dataUpdate {
            case .reloadSection(let sectionIndexBeforeUpdate, _):
                self.sectionReloads.insert(sectionIndexBeforeUpdate)
            case .reloadItem(let indexPairBeforeUpdate, _):
                self.itemReloads.insert(indexPairBeforeUpdate)
            default:
                result.append(dataUpdate)
            }
        }
        
        dataUpdates = result
    }
    
    private func processSectionUpdates(_ dataUpdates: inout [DataUpdate]) -> ([Int], [Int]) {
        var deletedSections = [Int]()
        var insertedSections = [Int]()
        
        var index: Int = 0
        var stop: Bool = false
        for dataUpdate in dataUpdates {
            guard !stop else { break }
            
            switch dataUpdate {
            case .deleteSection(let sectionIndex):
                deletedSections.append(sectionIndex)
                index += 1
            
                
            case .insertSection(let sectionIndex):
                insertedSections.append(sectionIndex)
                index += 1
                
            default:
                stop = true
                break
            }
        }
        
        dataUpdates = Array(dataUpdates[index...])
        return (deletedSections, insertedSections)
    }
    
    private mutating func addUpdateItems(_ dataUpdates: [DataUpdate]) {
        
        var dataUpdates = dataUpdates
        
        self.processReloads(&dataUpdates)
        
        dataUpdates.sort()
        
        let (deletedSections, insertedSections) = self.processSectionUpdates(&dataUpdates)

       
        
        var deletedItemsPerSection: [[Int]] = Array(repeating: [], count: dataSourceCounts.numberOfSections + insertedSections.count)
        var insertedItemsPerSection: [[Int]] = Array(repeating: [], count: dataSourceCounts.numberOfSections + insertedSections.count)
        
        
        for dataUpdate in dataUpdates {
            switch dataUpdate {
            case .deleteItem(let indexPair):
                deletedItemsPerSection[indexPair.section].append(indexPair.item)

            case .insertItem(let indexPair):
                insertedItemsPerSection[indexPair.section].append(indexPair.item)
            
            default:
                fatalError("Meh")
            }
        }
        
        sectionIndiciesAfterUpdate = calculateIndexShifts(numberOfItems: dataSourceCounts.numberOfSections, deletions: deletedSections, insertions: insertedSections)
        
        for (sectionIndexBeforeUpdate, section) in dataSourceCounts.sections.enumerated() {
            
            guard let sectionIndexAfterUpdate = sectionIndiciesAfterUpdate[sectionIndexBeforeUpdate]! else {
                // No need to explcitlty delete items of a section if the entire section is deleted
                continue
            }
            
            let deletedIndicies: [Int] = deletedItemsPerSection[sectionIndexBeforeUpdate].sorted()
            
            let insertedIndicies: [Int] = insertedItemsPerSection[sectionIndexAfterUpdate].sorted()
            
            let withinSectionMoves = calculateIndexShifts(numberOfItems: section.itemCount, deletions: deletedIndicies, insertions: insertedIndicies)
            
            for (indexBeforeUpdate, indexAfterUpdate) in withinSectionMoves {
                indexPairsAfterUpdate[IndexPair(item: indexBeforeUpdate, section: sectionIndexBeforeUpdate)] = indexAfterUpdate.map {
                    IndexPair(item: $0, section: sectionIndexAfterUpdate)
                }
            }
        }
    }
    
    private mutating func buildReverseAccessors() {
        indexPairsBeforeUpdate.removeAll()
        
        for (indexPairBeforeUpdate, indexPairAfterUpdate) in indexPairsAfterUpdate {
            if let indexPairAfterUpdate = indexPairAfterUpdate {
                indexPairsBeforeUpdate[indexPairAfterUpdate] = indexPairBeforeUpdate
            }
        }
    }
}



private func calculateIndexShifts(numberOfItems: Int, deletions: [Int], insertions: [Int]) -> [Int: Int?] {
    var result: [Int: Int?] = [:]
    
    var shiftedIndicies = Array(repeating: 0, count: numberOfItems)
    
    var counter = 0
    
    for i in 0..<shiftedIndicies.count {
        if counter < deletions.endIndex && deletions[counter] == i {
            shiftedIndicies[i] = -1
            counter += 1
        } else {
            shiftedIndicies[i] = i - counter
        }
    }
    
    
    counter = 0
    
    for i in 0..<shiftedIndicies.count {
        let indexAfterDelete = shiftedIndicies[i]
        if indexAfterDelete == -1 {
            continue
        }
        
        while counter < insertions.endIndex && insertions[counter] == indexAfterDelete + counter {
            counter += 1
        }
        
        shiftedIndicies[i] = indexAfterDelete + counter
    }
    
    
    for (i, j) in shiftedIndicies.enumerated() {
        result[i] = j < 0 ? nil : j
    }
    
    return result
}
