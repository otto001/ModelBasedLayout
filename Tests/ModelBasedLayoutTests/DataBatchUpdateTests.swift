//
//  DataBatchUpdateTests.swift
//  ModelBasedLayoutTests
//
//  Created by Matteo Ludwig on 18.07.23.
//

import XCTest
@testable import ModelBasedLayout

struct RandomNumberGeneratorWithSeed: RandomNumberGenerator {
    init(seed: Int) {
        // Set the random seed
        srand48(seed)
    }
    
    
    func next() -> UInt64 { return UInt64(drand48() * Double(UInt64.max)) }
}


final class DataBatchUpdateTests: XCTestCase {

    var rng = RandomNumberGeneratorWithSeed(seed: 0)
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDeleteItemOnly() throws {
        
        let dataSourceCounts = DataSourceCounts(sections: [8, 3])

        let updates: [DataUpdate] = [
            .deleteItem(indexPair: IndexPair(item: 3, section: 0)),
            .deleteItem(indexPair: IndexPair(item: 4, section: 0)),
            .deleteItem(indexPair: IndexPair(item: 6, section: 0)),
            
            .deleteItem(indexPair: IndexPair(item: 0, section: 1)),
            .deleteItem(indexPair: IndexPair(item: 2, section: 1)),
        ]
        let changes = DataBatchUpdate(dataSourceCounts: dataSourceCounts, updateItems: updates)
        let results: [IndexPair: IndexPair?] = [
            IndexPair(item: 0, section: 0): IndexPair(item: 0, section: 0),
            IndexPair(item: 1, section: 0): IndexPair(item: 1, section: 0),
            IndexPair(item: 2, section: 0): IndexPair(item: 2, section: 0),
            IndexPair(item: 3, section: 0): nil,
            IndexPair(item: 4, section: 0): nil,
            IndexPair(item: 5, section: 0): IndexPair(item: 3, section: 0),
            IndexPair(item: 6, section: 0): nil,
            IndexPair(item: 7, section: 0): IndexPair(item: 4, section: 0),
            
            IndexPair(item: 0, section: 1): nil,
            IndexPair(item: 1, section: 1): IndexPair(item: 0, section: 1),
            IndexPair(item: 2, section: 1): nil,
        ]
        
        for indexPair in dataSourceCounts.indexPairs(for: 0...dataSourceCounts.itemsCount-1) {
            XCTAssertEqual(changes.indexPairAfterUpdate(for: indexPair), results[indexPair])
        }
        
    }
    
    func testInsertItemOnly() throws {
        
        let dataSourceCounts = DataSourceCounts(sections: [8, 2])

        let updates: [DataUpdate] = [
            .insertItem(indexPair: IndexPair(item: 3, section: 0)),
            .insertItem(indexPair: IndexPair(item: 4, section: 0)),
            .insertItem(indexPair: IndexPair(item: 6, section: 0)),
            
            .insertItem(indexPair: IndexPair(item: 0, section: 1)),
            .insertItem(indexPair: IndexPair(item: 3, section: 1)),
        ]
        let changes = DataBatchUpdate(dataSourceCounts: dataSourceCounts, updateItems: updates)
        let results: [IndexPair: IndexPair?] = [
            IndexPair(item: 0, section: 0): IndexPair(item: 0, section: 0),
            IndexPair(item: 1, section: 0): IndexPair(item: 1, section: 0),
            IndexPair(item: 2, section: 0): IndexPair(item: 2, section: 0),
            IndexPair(item: 3, section: 0): IndexPair(item: 5, section: 0),
            IndexPair(item: 4, section: 0): IndexPair(item: 7, section: 0),
            IndexPair(item: 5, section: 0): IndexPair(item: 8, section: 0),
            IndexPair(item: 6, section: 0): IndexPair(item: 9, section: 0),
            IndexPair(item: 7, section: 0): IndexPair(item: 10, section: 0),
            
            IndexPair(item: 0, section: 1): IndexPair(item: 1, section: 1),
            IndexPair(item: 1, section: 1): IndexPair(item: 2, section: 1),
        ]
        
        for indexPair in dataSourceCounts.indexPairs(for: 0..<dataSourceCounts.itemsCount) {
            XCTAssertEqual(changes.indexPairAfterUpdate(for: indexPair), results[indexPair])
        }
    }
    
    func testDeleteSection() throws {
        
        let dataSourceCounts = DataSourceCounts(sections: [8, 3, 2])

        let updates: [DataUpdate] = [
            .deleteItem(indexPair: IndexPair(item: 3, section: 0)),
            .deleteItem(indexPair: IndexPair(item: 4, section: 0)),
            .deleteItem(indexPair: IndexPair(item: 6, section: 0)),
            
            .deleteSection(sectionIndex: 1),
            .deleteItem(indexPair: IndexPair(item: 0, section: 1)),
            .deleteItem(indexPair: IndexPair(item: 1, section: 1)),
            .deleteItem(indexPair: IndexPair(item: 2, section: 1)),
        ]
        let changes = DataBatchUpdate(dataSourceCounts: dataSourceCounts, updateItems: updates)
        let results: [IndexPair: IndexPair?] = [
            IndexPair(item: 0, section: 0): IndexPair(item: 0, section: 0),
            IndexPair(item: 1, section: 0): IndexPair(item: 1, section: 0),
            IndexPair(item: 2, section: 0): IndexPair(item: 2, section: 0),
            IndexPair(item: 3, section: 0): nil,
            IndexPair(item: 4, section: 0): nil,
            IndexPair(item: 5, section: 0): IndexPair(item: 3, section: 0),
            IndexPair(item: 6, section: 0): nil,
            IndexPair(item: 7, section: 0): IndexPair(item: 4, section: 0),
            
            IndexPair(item: 0, section: 1): nil,
            IndexPair(item: 1, section: 1): nil,
            IndexPair(item: 2, section: 1): nil,
            
            IndexPair(item: 0, section: 2): IndexPair(item: 0, section: 1),
            IndexPair(item: 1, section: 2): IndexPair(item: 1, section: 1),
        ]
        
        for indexPair in dataSourceCounts.indexPairs(for: 0..<dataSourceCounts.itemsCount) {
            XCTAssertEqual(changes.indexPairAfterUpdate(for: indexPair), results[indexPair])
        }
        
    }
    
    func testDeleteSectionOnly() throws {
        
        let dataSourceCounts = DataSourceCounts(sections: [8, 3, 2])

        let updates: [DataUpdate] = [
            .deleteItem(indexPair: IndexPair(item: 3, section: 0)),
            .deleteItem(indexPair: IndexPair(item: 4, section: 0)),
            .deleteItem(indexPair: IndexPair(item: 6, section: 0)),
            
            .deleteSection(sectionIndex: 1),
        ]
        let changes = DataBatchUpdate(dataSourceCounts: dataSourceCounts, updateItems: updates)
        let results: [IndexPair: IndexPair?] = [
            IndexPair(item: 0, section: 0): IndexPair(item: 0, section: 0),
            IndexPair(item: 1, section: 0): IndexPair(item: 1, section: 0),
            IndexPair(item: 2, section: 0): IndexPair(item: 2, section: 0),
            IndexPair(item: 3, section: 0): nil,
            IndexPair(item: 4, section: 0): nil,
            IndexPair(item: 5, section: 0): IndexPair(item: 3, section: 0),
            IndexPair(item: 6, section: 0): nil,
            IndexPair(item: 7, section: 0): IndexPair(item: 4, section: 0),
            
            IndexPair(item: 0, section: 1): nil,
            IndexPair(item: 1, section: 1): nil,
            IndexPair(item: 2, section: 1): nil,
            
            IndexPair(item: 0, section: 2): IndexPair(item: 0, section: 1),
            IndexPair(item: 1, section: 2): IndexPair(item: 1, section: 1),
        ]
        
        for indexPair in dataSourceCounts.indexPairs(for: 0..<dataSourceCounts.itemsCount) {
            XCTAssertEqual(changes.indexPairAfterUpdate(for: indexPair), results[indexPair])
        }
        
    }
    
    func testInsertSection() throws {
        
        let dataSourceCounts = DataSourceCounts(sections: [3, 3])

        let updates: [DataUpdate] = [
            .insertSection(sectionIndex: 1),
            .insertItem(indexPair: IndexPair(item: 0, section: 1)),
            .insertItem(indexPair: IndexPair(item: 1, section: 1)),
            .insertItem(indexPair: IndexPair(item: 2, section: 1)),
        ]
        let changes = DataBatchUpdate(dataSourceCounts: dataSourceCounts, updateItems: updates)
        let results: [IndexPair: IndexPair?] = [
            IndexPair(item: 0, section: 0): IndexPair(item: 0, section: 0),
            IndexPair(item: 1, section: 0): IndexPair(item: 1, section: 0),
            IndexPair(item: 2, section: 0): IndexPair(item: 2, section: 0),
            
            IndexPair(item: 0, section: 1): IndexPair(item: 0, section: 2),
            IndexPair(item: 1, section: 1): IndexPair(item: 1, section: 2),
            IndexPair(item: 2, section: 1): IndexPair(item: 2, section: 2),
        ]
        
        for indexPair in dataSourceCounts.indexPairs(for: 0..<dataSourceCounts.itemsCount) {
            XCTAssertEqual(changes.indexPairAfterUpdate(for: indexPair), results[indexPair])
        }
        
    }
    
    func testInsertDeleteSection() throws {
        
        let dataSourceCounts = DataSourceCounts(sections: [5, 3, 3])

        let updates: [DataUpdate] = [
            .deleteItem(indexPair: IndexPair(item: 1, section: 0)),
            .deleteItem(indexPair: IndexPair(item: 3, section: 0)),
            .insertItem(indexPair: IndexPair(item: 1, section: 0)),
            .insertItem(indexPair: IndexPair(item: 3, section: 0)),
            
            .deleteItem(indexPair: IndexPair(item: 1, section: 1)),
            .deleteSection(sectionIndex: 1),
            
            .insertSection(sectionIndex: 1),
            .insertItem(indexPair: IndexPair(item: 0, section: 1)),
            .insertItem(indexPair: IndexPair(item: 1, section: 1)),
            .insertItem(indexPair: IndexPair(item: 2, section: 1)),
        ]
        let changes = DataBatchUpdate(dataSourceCounts: dataSourceCounts, updateItems: updates)
        let results: [IndexPair: IndexPair?] = [
            IndexPair(item: 0, section: 0): IndexPair(item: 0, section: 0),
            IndexPair(item: 1, section: 0): nil,
            IndexPair(item: 2, section: 0): IndexPair(item: 2, section: 0),
            IndexPair(item: 3, section: 0): nil,
            IndexPair(item: 4, section: 0): IndexPair(item: 4, section: 0),
            
            IndexPair(item: 0, section: 1): nil,
            IndexPair(item: 1, section: 1): nil,
            IndexPair(item: 2, section: 1): nil,
            
            IndexPair(item: 0, section: 2): IndexPair(item: 0, section: 2),
            IndexPair(item: 1, section: 2): IndexPair(item: 1, section: 2),
            IndexPair(item: 2, section: 2): IndexPair(item: 2, section: 2),
        ]
        
        for indexPair in dataSourceCounts.indexPairs(for: 0..<dataSourceCounts.itemsCount) {
            XCTAssertEqual(changes.indexPairAfterUpdate(for: indexPair), results[indexPair])
        }
        
    }
    
    func testMoveItemWithinSection() throws {
        
        let dataSourceCounts = DataSourceCounts(sections: [3, 3, 5, 5])

        let updates: [DataUpdate] = [
            .moveItem(indexPairBeforeUpdate: IndexPair(item: 0, section: 0), indexPairAfterUpdate: IndexPair(item: 1, section: 0)),
            
            .moveItem(indexPairBeforeUpdate: IndexPair(item: 0, section: 1), indexPairAfterUpdate: IndexPair(item: 2, section: 1)),
            
            .moveItem(indexPairBeforeUpdate: IndexPair(item: 1, section: 2), indexPairAfterUpdate: IndexPair(item: 3, section: 2)),
            
            .moveItem(indexPairBeforeUpdate: IndexPair(item: 1, section: 3), indexPairAfterUpdate: IndexPair(item: 3, section: 3)),
            .moveItem(indexPairBeforeUpdate: IndexPair(item: 2, section: 3), indexPairAfterUpdate: IndexPair(item: 4, section: 3)),
        ]
        
        let changes = DataBatchUpdate(dataSourceCounts: dataSourceCounts, updateItems: updates)
        let results: [IndexPair: IndexPair?] = [
            IndexPair(item: 0, section: 0): IndexPair(item: 1, section: 0),
            IndexPair(item: 1, section: 0): IndexPair(item: 0, section: 0),
            IndexPair(item: 2, section: 0): IndexPair(item: 2, section: 0),
            
            IndexPair(item: 0, section: 1): IndexPair(item: 2, section: 1),
            IndexPair(item: 1, section: 1): IndexPair(item: 0, section: 1),
            IndexPair(item: 2, section: 1): IndexPair(item: 1, section: 1),
            
            IndexPair(item: 0, section: 2): IndexPair(item: 0, section: 2),
            IndexPair(item: 1, section: 2): IndexPair(item: 3, section: 2),
            IndexPair(item: 2, section: 2): IndexPair(item: 1, section: 2),
            IndexPair(item: 3, section: 2): IndexPair(item: 2, section: 2),
            IndexPair(item: 4, section: 2): IndexPair(item: 4, section: 2),
            
            IndexPair(item: 0, section: 3): IndexPair(item: 0, section: 3),
            IndexPair(item: 1, section: 3): IndexPair(item: 3, section: 3),
            IndexPair(item: 2, section: 3): IndexPair(item: 4, section: 3),
            IndexPair(item: 3, section: 3): IndexPair(item: 1, section: 3),
            IndexPair(item: 4, section: 3): IndexPair(item: 2, section: 3),
        ]
        
        for indexPair in dataSourceCounts.indexPairs(for: 0..<dataSourceCounts.itemsCount) {
            XCTAssertEqual(changes.indexPairAfterUpdate(for: indexPair), results[indexPair])
        }
    }
    
    func testMoveItemOutsideOfSection() throws {
        
        let dataSourceCounts = DataSourceCounts(sections: [3, 3])

        let updates: [DataUpdate] = [
            .moveItem(indexPairBeforeUpdate: IndexPair(item: 0, section: 0), indexPairAfterUpdate: IndexPair(item: 1, section: 1))
        ]
        
        let changes = DataBatchUpdate(dataSourceCounts: dataSourceCounts, updateItems: updates)
        let results: [IndexPair: IndexPair?] = [
            IndexPair(item: 0, section: 0): IndexPair(item: 1, section: 1),
            IndexPair(item: 1, section: 0): IndexPair(item: 0, section: 0),
            IndexPair(item: 2, section: 0): IndexPair(item: 1, section: 0),
            
            IndexPair(item: 0, section: 1): IndexPair(item: 0, section: 1),
            IndexPair(item: 1, section: 1): IndexPair(item: 2, section: 1),
            IndexPair(item: 2, section: 1): IndexPair(item: 3, section: 1),
        ]
        
        for indexPair in dataSourceCounts.indexPairs(for: 0..<dataSourceCounts.itemsCount) {
            XCTAssertEqual(changes.indexPairAfterUpdate(for: indexPair), results[indexPair])
        }
    }
    
    func testMixed() throws {
        
        let dataSourceCounts = DataSourceCounts(sections: [5, 3, 3, 3, 1, 1, 1])

        let updates: [DataUpdate] = [
            .deleteSection(sectionIndex: 1),
            .deleteItem(indexPair: IndexPair(item: 1, section: 0)),
            
            .insertSection(sectionIndex: 2),
            .insertItem(indexPair: IndexPair(item: 2, section: 0)),
            
            .moveSection(sectionIndexBeforeUpdate: 3, sectionIndexAfterUpdate: 5),
            .moveSection(sectionIndexBeforeUpdate: 0, sectionIndexAfterUpdate: 6),
            
        ]
        
        // d1, i2, m2:3
        //
        //   0 1 2 3 4 5 6
        //   a b c d e f g
        // d a c d e f g
        // i a c x d e f g
        // m a c d x e f g
        //   0 - 1 2 4 5 6
        
        
        
        let changes = DataBatchUpdate(dataSourceCounts: dataSourceCounts, updateItems: updates)
        let results: [IndexPair: IndexPair?] = [
            
            IndexPair(item: 0, section: 0): IndexPair(item: 0, section: 6),
            IndexPair(item: 1, section: 0): nil,
            IndexPair(item: 2, section: 0): IndexPair(item: 1, section: 6),
            // item inserted here
            IndexPair(item: 3, section: 0): IndexPair(item: 3, section: 6),
            IndexPair(item: 4, section: 0): IndexPair(item: 4, section: 6),
            
            IndexPair(item: 0, section: 1): nil,
            IndexPair(item: 1, section: 1): nil,
            IndexPair(item: 2, section: 1): nil,
            
            IndexPair(item: 0, section: 2): IndexPair(item: 0, section: 0),
            IndexPair(item: 1, section: 2): IndexPair(item: 1, section: 0),
            IndexPair(item: 2, section: 2): IndexPair(item: 2, section: 0),
            
            // section inserted here
            
            IndexPair(item: 0, section: 3): IndexPair(item: 0, section: 5),
            IndexPair(item: 1, section: 3): IndexPair(item: 1, section: 5),
            IndexPair(item: 2, section: 3): IndexPair(item: 2, section: 5),
            
            IndexPair(item: 0, section: 4): IndexPair(item: 0, section: 2),
            
            IndexPair(item: 0, section: 5): IndexPair(item: 0, section: 3),
            
            IndexPair(item: 0, section: 6): IndexPair(item: 0, section: 4),
        ]
        
        for indexPair in dataSourceCounts.indexPairs(for: 0..<dataSourceCounts.itemsCount) {
            XCTAssertEqual(changes.indexPairAfterUpdate(for: indexPair), results[indexPair])
        }
    }
    
    
    func testDeletionPerformance() throws {
        let sections = Array(repeating: 1, count: 100_000)
        let dataSourceCounts = DataSourceCounts(sections: sections)
        var updates: [DataUpdate] = []
        for _ in 0..<10_000 {
            updates.append(.deleteSection(sectionIndex: Int.random(in: 0..<100_000, using: &rng)))
        }
        
        self.measure {
            _ = DataBatchUpdate(dataSourceCounts: dataSourceCounts, updateItems: updates)
        }
    }
    
    func testInsertionsPerformance() throws {
        let sections = Array(repeating: 1, count: 100_000)
        let dataSourceCounts = DataSourceCounts(sections: sections)
        var updates: [DataUpdate] = []
        for _ in 0..<10_000 {
            updates.append(.insertSection(sectionIndex: Int.random(in: 0...100_000, using: &rng)))
        }
        
        self.measure {
            _ = DataBatchUpdate(dataSourceCounts: dataSourceCounts, updateItems: updates)
        }
    }
}
