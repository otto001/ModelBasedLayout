//
//  DataBatchUpdate.swift
//  ModelBasedCollectionView
//
//  Created by Matteo Ludwig on 18.07.23.
//

import UIKit



struct DataBatchUpdate {

    private var indexPathsAfterUpdate: [IndexPath: IndexPath?] = [:]
    private var indexPathsBeforeUpdate: [IndexPath: IndexPath] = [:]
    
    private var sectionIndiciesAfterUpdate: [Int: Int?] = [:]
    
    private var dataSourceCounts: DataSourceCounts
    
    init(dataSourceCounts: DataSourceCounts, updateItems: [DataUpdate]) {
        self.dataSourceCounts = dataSourceCounts
        
        addUpdateItems(updateItems)
        buildReverseAccessors()
    }
    
    init(dataSourceCounts: DataSourceCounts, updateItems: [UICollectionViewUpdateItem]) {
        self = .init(dataSourceCounts: dataSourceCounts, updateItems: updateItems.compactMap {DataUpdate($0)})
    }
    
    func indexPathAfterUpdate(for indexPath: IndexPath) -> IndexPath? {
        guard sectionIndiciesAfterUpdate[indexPath.section] != nil else { return nil }
        return indexPathsAfterUpdate[indexPath] ?? nil
    }
    
    func indexPathBeforeUpdate(for indexPath: IndexPath) -> IndexPath? {
        //guard sectionIndiciesAfterUpdate[indexPath.section] != nil else { return nil }
        return indexPathsBeforeUpdate[indexPath]
    }
    
    
    private mutating func addUpdateItems(_ dataUpdates: [DataUpdate]) {
        
        
        let dataUpdates = dataUpdates.sorted()
        

        var deletedSections = [Int]()
        var insertedSections = [Int]()
        
        var index: Int = 0
        for dataUpdate in dataUpdates {
            switch dataUpdate {
            case .deleteSection(let sectionIndex):
                deletedSections.append(sectionIndex)
                index += 1
            
                
            case .insertSection(let sectionIndex):
                insertedSections.append(sectionIndex)
                index += 1
                
            default:
                break
            }
        }
        
        var deletedItemsPerSection: [[Int]] = Array(repeating: [], count: dataSourceCounts.numberOfSections + insertedSections.count)
        var insertedItemsPerSection: [[Int]] = Array(repeating: [], count: dataSourceCounts.numberOfSections + insertedSections.count)
        
        
        for dataUpdate in dataUpdates[index...] {
            switch dataUpdate {
            case .deleteItem(let indexPath):
                deletedItemsPerSection[indexPath.section].append(indexPath.item)

            case .insertItem(let indexPath):
                insertedItemsPerSection[indexPath.section].append(indexPath.item)

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
                indexPathsAfterUpdate[IndexPath(item: indexBeforeUpdate, section: sectionIndexBeforeUpdate)] = indexAfterUpdate.map {
                    IndexPath(item: $0, section: sectionIndexAfterUpdate)
                }
            }
        }
    }
    
    private mutating func buildReverseAccessors() {
        for (indexPathBeforeUpdate, indexPathAfterUpdate) in indexPathsAfterUpdate {
            if let indexPathAfterUpdate = indexPathAfterUpdate {
                indexPathsBeforeUpdate[indexPathAfterUpdate] = indexPathBeforeUpdate
            }
        }
    }
}



func calculateIndexShifts(numberOfItems: Int, deletions: [Int], insertions: [Int]) -> [Int: Int?] {
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
