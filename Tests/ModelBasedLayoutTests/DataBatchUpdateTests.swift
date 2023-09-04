//
//  ModelBasedCollectionViewTests.swift
//  ModelBasedCollectionViewTests
//
//  Created by Matteo Ludwig on 18.07.23.
//

import XCTest
@testable import ModelBasedLayout

final class DataBatchUpdateTests: XCTestCase {

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
        
        for indexPair in dataSourceCounts.indexPairs(startIndex: 0, endIndex: dataSourceCounts.itemsCount) {
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
        
        for indexPair in dataSourceCounts.indexPairs(startIndex: 0, endIndex: dataSourceCounts.itemsCount) {
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
        
        for indexPair in dataSourceCounts.indexPairs(startIndex: 0, endIndex: dataSourceCounts.itemsCount) {
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
        
        for indexPair in dataSourceCounts.indexPairs(startIndex: 0, endIndex: dataSourceCounts.itemsCount) {
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
        
        for indexPair in dataSourceCounts.indexPairs(startIndex: 0, endIndex: dataSourceCounts.itemsCount) {
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
        
        for indexPair in dataSourceCounts.indexPairs(startIndex: 0, endIndex: dataSourceCounts.itemsCount) {
            XCTAssertEqual(changes.indexPairAfterUpdate(for: indexPair), results[indexPair])
        }
        
    }  
}
