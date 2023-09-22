//
//  DataBatchUpdate.swift
//  ModelBasedLayout
//
//  Created by Matteo Ludwig on 18.07.23.
//

import UIKit



struct DataBatchUpdate {

    private var indexPairsAfterUpdate: [IndexPair: IndexPair?] = [:]
    private var indexPairsBeforeUpdate: [IndexPair: IndexPair] = [:]
    
    private var sectionIndiciesAfterUpdate: [Int: Int] = [:]
    
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
                
            case .moveSection(let sectionIndexBeforeUpdate, let sectionIndexAfterUpdate):
                deletedSections.append(sectionIndexBeforeUpdate)
                insertedSections.append(sectionIndexAfterUpdate)
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
        
        var sectionSummary: IndexBasedSummary = .init(initialItemCount: dataSourceCounts.numberOfSections)
        var itemInserts: [IndexPair] = []
        var itemDeletions: [IndexPair] = []
        var itemMoves: [(IndexPair, IndexPair)] = []
        
        for dataUpdate in dataUpdates {
            switch dataUpdate {
            case .deleteSection(let sectionIndex):
                sectionSummary.deletions.append(sectionIndex)
                
            case .insertSection(let sectionIndex):
                sectionSummary.insertions.append(sectionIndex)
                
            case .moveSection(let sectionIndexBeforeUpdate, let sectionIndexAfterUpdate):
                sectionSummary.moves.append((sectionIndexBeforeUpdate, sectionIndexAfterUpdate))
                
            case .reloadSection(let sectionIndexBeforeUpdate, _):
                sectionReloads.insert(sectionIndexBeforeUpdate)
                
            case .deleteItem(let indexPair):
                itemDeletions.append(indexPair)
                
            case .insertItem(let indexPair):
                itemInserts.append(indexPair)
                
            case .moveItem(let indexPairBeforeUpdate, let indexPairAfterUpdate):
                itemMoves.append((indexPairBeforeUpdate, indexPairAfterUpdate))
                
            case .reloadItem(let indexPairBeforeUpdate, _):
                itemReloads.insert(indexPairBeforeUpdate)
            }
        }
        
        sectionIndiciesAfterUpdate = calculateIndexShifts(summary: sectionSummary)
        let moves = calculateIndexShifts(summary: IndexBasedSummary(initialItemCount: dataSourceCounts.itemsCount + sectionSummary.insertions.count,
                                                                    moves: sectionSummary.moves))
        
        var perSectionSummaries: [IndexBasedSummary] = Array(repeating: .init(), count: dataSourceCounts.numberOfSections + sectionSummary.insertions.count)
        
        for indexPair in itemDeletions {
            guard let sectionIndexAfterUpdate = sectionIndiciesAfterUpdate[indexPair.section] else { continue }
            perSectionSummaries[sectionIndexAfterUpdate].deletions.append(indexPair.item)
        }
        
        for indexPair in itemInserts {
            guard let sectionIndexAfterUpdate = moves[indexPair.section] else { continue }
            perSectionSummaries[sectionIndexAfterUpdate].insertions.append(indexPair.item)
        }
        
        for (indexPairBeforeUpdate, indexPairAfterUpdate) in itemMoves {
            if indexPairBeforeUpdate.section == indexPairAfterUpdate.section {
                perSectionSummaries[indexPairAfterUpdate.section].moves.append((indexPairBeforeUpdate.item, indexPairAfterUpdate.item))
            } else {
                perSectionSummaries[indexPairBeforeUpdate.section].deletions.append(indexPairBeforeUpdate.item)
                perSectionSummaries[indexPairAfterUpdate.section].insertions.append(indexPairAfterUpdate.item)
            }
        }
        
        for (sectionIndexBeforeUpdate, section) in dataSourceCounts.sections.enumerated() {
            
            guard let sectionIndexAfterUpdate = sectionIndiciesAfterUpdate[sectionIndexBeforeUpdate] else {
                // No need to explcitlty delete items of a section if the entire section is deleted
                continue
            }
            
            var summary = perSectionSummaries[sectionIndexAfterUpdate]
            summary.initialItemCount = section.itemCount
            
            let withinSectionMoves = calculateIndexShifts(summary: summary)
            
            for indexBeforeUpdate in 0..<section.itemCount {
                indexPairsAfterUpdate[IndexPair(item: indexBeforeUpdate, section: sectionIndexBeforeUpdate)] = withinSectionMoves[indexBeforeUpdate].map {
                    IndexPair(item: $0, section: sectionIndexAfterUpdate)
                }
            }
        }
        
        for (indexPairBeforeUpdate, indexPairAfterUpdate) in itemMoves {
            if indexPairBeforeUpdate.section != indexPairAfterUpdate.section {
                indexPairsAfterUpdate[indexPairBeforeUpdate] = indexPairAfterUpdate
            }
        }
//
//        let s = indexPairsAfterUpdate.sorted(by: { (p1, p2) in
//            p1.key < p2.key
//        })
//        for (a, b) in s {
//            print("\(a) -> \(b)")
//        }
//
        print()
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

struct IndexBasedSummary {
    var initialItemCount: Int
    var deletions: [Int]
    var insertions: [Int]
    var moves: [(Int, Int)]
    
    init(initialItemCount: Int = 0, deletions: [Int] = [], insertions: [Int] = [], moves: [(Int, Int)] = []) {
        self.initialItemCount = initialItemCount
        self.deletions = deletions
        self.insertions = insertions
        self.moves = moves
    }
}


private func calculateIndexShifts(summary: IndexBasedSummary) -> [Int: Int] {
    var shiftedIndicies = ContiguousArray(repeating: 0, count: summary.initialItemCount)

    for i in 0..<shiftedIndicies.count {
        shiftedIndicies[i] = i
    }
    
    // Deletions
    if !summary.deletions.isEmpty {
        for deletion in summary.deletions {
            shiftedIndicies[deletion] = -1
        }
        shiftedIndicies = shiftedIndicies.filter { $0 >= 0 }
    }
    
    // Insertions
    if !summary.insertions.isEmpty {
        
        var insertionShifts = ContiguousArray(repeating: 0, count: summary.initialItemCount + summary.insertions.count)
        for insertion in summary.insertions {
            insertionShifts[insertion] += 1
        }
        
        for i in insertionShifts.indices {
            while insertionShifts[i] > 0 {
                shiftedIndicies.insert(-2, at: i)
                insertionShifts[i] -= 1
            }
        }
    }
    
    
    // Moves
    if !summary.moves.isEmpty {
        
        
        var afterMoves = ContiguousArray(repeating: -3, count: shiftedIndicies.count)
        
        for move in summary.moves {
            afterMoves[move.1] = shiftedIndicies[move.0]
            shiftedIndicies[move.0] = -3
        }
        let indiciesNotMovedExplicitly = shiftedIndicies.filter { $0 != -3 }
        
        var notMovedIndex = 0
        
        for i in afterMoves.indices {
            guard afterMoves[i] == -3 else { continue }
            afterMoves[i] = indiciesNotMovedExplicitly[notMovedIndex]
            notMovedIndex += 1
        }
        shiftedIndicies = afterMoves
    }
    
    var result: [Int: Int] = [:]

    for (i, j) in shiftedIndicies.enumerated() {
        guard j >= 0 else { continue }
        result[j] = i
    }
    
    return result
}
