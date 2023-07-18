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
        
        let layoutData = ModelBasedLayoutData(sections: [8, 3], collectionViewSize: .zero)

        let updates: [DataUpdate] = [
            .deleteItem(indexPath: IndexPath(item: 3, section: 0)),
            .deleteItem(indexPath: IndexPath(item: 4, section: 0)),
            .deleteItem(indexPath: IndexPath(item: 6, section: 0)),
            
            .deleteItem(indexPath: IndexPath(item: 0, section: 1)),
            .deleteItem(indexPath: IndexPath(item: 2, section: 1)),
        ]
        let changes = DataBatchUpdate(layoutData: layoutData, updateItems: updates)
        let results: [IndexPath: IndexPath?] = [
            IndexPath(item: 0, section: 0): IndexPath(item: 0, section: 0),
            IndexPath(item: 1, section: 0): IndexPath(item: 1, section: 0),
            IndexPath(item: 2, section: 0): IndexPath(item: 2, section: 0),
            IndexPath(item: 3, section: 0): nil,
            IndexPath(item: 4, section: 0): nil,
            IndexPath(item: 5, section: 0): IndexPath(item: 3, section: 0),
            IndexPath(item: 6, section: 0): nil,
            IndexPath(item: 7, section: 0): IndexPath(item: 4, section: 0),
            
            IndexPath(item: 0, section: 1): nil,
            IndexPath(item: 1, section: 1): IndexPath(item: 0, section: 1),
            IndexPath(item: 2, section: 1): nil,
        ]
        
        for indexPath in layoutData.indexPaths(startIndex: 0, endIndex: layoutData.itemsCount) {
            XCTAssertEqual(changes.indexPathAfterUpdate(for: indexPath), results[indexPath])
        }
        
    }
    
    func testInsertItemOnly() throws {
        
        let layoutData = ModelBasedLayoutData(sections: [8, 2], collectionViewSize: .zero)

        let updates: [DataUpdate] = [
            .insertItem(indexPath: IndexPath(item: 3, section: 0)),
            .insertItem(indexPath: IndexPath(item: 4, section: 0)),
            .insertItem(indexPath: IndexPath(item: 6, section: 0)),
            
            .insertItem(indexPath: IndexPath(item: 0, section: 1)),
            .insertItem(indexPath: IndexPath(item: 3, section: 1)),
        ]
        let changes = DataBatchUpdate(layoutData: layoutData, updateItems: updates)
        let results: [IndexPath: IndexPath?] = [
            IndexPath(item: 0, section: 0): IndexPath(item: 0, section: 0),
            IndexPath(item: 1, section: 0): IndexPath(item: 1, section: 0),
            IndexPath(item: 2, section: 0): IndexPath(item: 2, section: 0),
            IndexPath(item: 3, section: 0): IndexPath(item: 5, section: 0),
            IndexPath(item: 4, section: 0): IndexPath(item: 7, section: 0),
            IndexPath(item: 5, section: 0): IndexPath(item: 8, section: 0),
            IndexPath(item: 6, section: 0): IndexPath(item: 9, section: 0),
            IndexPath(item: 7, section: 0): IndexPath(item: 10, section: 0),
            
            IndexPath(item: 0, section: 1): IndexPath(item: 1, section: 1),
            IndexPath(item: 1, section: 1): IndexPath(item: 2, section: 1),
        ]
        
        for indexPath in layoutData.indexPaths(startIndex: 0, endIndex: layoutData.itemsCount) {
            XCTAssertEqual(changes.indexPathAfterUpdate(for: indexPath), results[indexPath])
        }
    }
    
    func testDeleteSection() throws {
        
        let layoutData = ModelBasedLayoutData(sections: [8, 3, 2], collectionViewSize: .zero)

        let updates: [DataUpdate] = [
            .deleteItem(indexPath: IndexPath(item: 3, section: 0)),
            .deleteItem(indexPath: IndexPath(item: 4, section: 0)),
            .deleteItem(indexPath: IndexPath(item: 6, section: 0)),
            
            .deleteSection(sectionIndex: 1),
            .deleteItem(indexPath: IndexPath(item: 0, section: 1)),
            .deleteItem(indexPath: IndexPath(item: 1, section: 1)),
            .deleteItem(indexPath: IndexPath(item: 2, section: 1)),
        ]
        let changes = DataBatchUpdate(layoutData: layoutData, updateItems: updates)
        let results: [IndexPath: IndexPath?] = [
            IndexPath(item: 0, section: 0): IndexPath(item: 0, section: 0),
            IndexPath(item: 1, section: 0): IndexPath(item: 1, section: 0),
            IndexPath(item: 2, section: 0): IndexPath(item: 2, section: 0),
            IndexPath(item: 3, section: 0): nil,
            IndexPath(item: 4, section: 0): nil,
            IndexPath(item: 5, section: 0): IndexPath(item: 3, section: 0),
            IndexPath(item: 6, section: 0): nil,
            IndexPath(item: 7, section: 0): IndexPath(item: 4, section: 0),
            
            IndexPath(item: 0, section: 1): nil,
            IndexPath(item: 1, section: 1): nil,
            IndexPath(item: 2, section: 1): nil,
            
            IndexPath(item: 0, section: 2): IndexPath(item: 0, section: 1),
            IndexPath(item: 1, section: 2): IndexPath(item: 1, section: 1),
        ]
        
        for indexPath in layoutData.indexPaths(startIndex: 0, endIndex: layoutData.itemsCount) {
            XCTAssertEqual(changes.indexPathAfterUpdate(for: indexPath), results[indexPath])
        }
        
    }
    
    func testDeleteSectionOnly() throws {
        
        let layoutData = ModelBasedLayoutData(sections: [8, 3, 2], collectionViewSize: .zero)

        let updates: [DataUpdate] = [
            .deleteItem(indexPath: IndexPath(item: 3, section: 0)),
            .deleteItem(indexPath: IndexPath(item: 4, section: 0)),
            .deleteItem(indexPath: IndexPath(item: 6, section: 0)),
            
            .deleteSection(sectionIndex: 1),
        ]
        let changes = DataBatchUpdate(layoutData: layoutData, updateItems: updates)
        let results: [IndexPath: IndexPath?] = [
            IndexPath(item: 0, section: 0): IndexPath(item: 0, section: 0),
            IndexPath(item: 1, section: 0): IndexPath(item: 1, section: 0),
            IndexPath(item: 2, section: 0): IndexPath(item: 2, section: 0),
            IndexPath(item: 3, section: 0): nil,
            IndexPath(item: 4, section: 0): nil,
            IndexPath(item: 5, section: 0): IndexPath(item: 3, section: 0),
            IndexPath(item: 6, section: 0): nil,
            IndexPath(item: 7, section: 0): IndexPath(item: 4, section: 0),
            
            IndexPath(item: 0, section: 1): nil,
            IndexPath(item: 1, section: 1): nil,
            IndexPath(item: 2, section: 1): nil,
            
            IndexPath(item: 0, section: 2): IndexPath(item: 0, section: 1),
            IndexPath(item: 1, section: 2): IndexPath(item: 1, section: 1),
        ]
        
        for indexPath in layoutData.indexPaths(startIndex: 0, endIndex: layoutData.itemsCount) {
            XCTAssertEqual(changes.indexPathAfterUpdate(for: indexPath), results[indexPath])
        }
        
    }
    
    func testInsertSection() throws {
        
        let layoutData = ModelBasedLayoutData(sections: [3, 3], collectionViewSize: .zero)

        let updates: [DataUpdate] = [
            .insertSection(sectionIndex: 1),
            .insertItem(indexPath: IndexPath(item: 0, section: 1)),
            .insertItem(indexPath: IndexPath(item: 1, section: 1)),
            .insertItem(indexPath: IndexPath(item: 2, section: 1)),
        ]
        let changes = DataBatchUpdate(layoutData: layoutData, updateItems: updates)
        let results: [IndexPath: IndexPath?] = [
            IndexPath(item: 0, section: 0): IndexPath(item: 0, section: 0),
            IndexPath(item: 1, section: 0): IndexPath(item: 1, section: 0),
            IndexPath(item: 2, section: 0): IndexPath(item: 2, section: 0),
            
            IndexPath(item: 0, section: 1): IndexPath(item: 0, section: 2),
            IndexPath(item: 1, section: 1): IndexPath(item: 1, section: 2),
            IndexPath(item: 2, section: 1): IndexPath(item: 2, section: 2),
        ]
        
        for indexPath in layoutData.indexPaths(startIndex: 0, endIndex: layoutData.itemsCount) {
            XCTAssertEqual(changes.indexPathAfterUpdate(for: indexPath), results[indexPath])
        }
        
    }
    
    func testInsertDeleteSection() throws {
        
        let layoutData = ModelBasedLayoutData(sections: [5, 3, 3], collectionViewSize: .zero)

        let updates: [DataUpdate] = [
            .deleteItem(indexPath: IndexPath(item: 1, section: 0)),
            .deleteItem(indexPath: IndexPath(item: 3, section: 0)),
            .insertItem(indexPath: IndexPath(item: 1, section: 0)),
            .insertItem(indexPath: IndexPath(item: 3, section: 0)),
            
            .deleteItem(indexPath: IndexPath(item: 1, section: 1)),
            .deleteSection(sectionIndex: 1),
            
            .insertSection(sectionIndex: 1),
            .insertItem(indexPath: IndexPath(item: 0, section: 1)),
            .insertItem(indexPath: IndexPath(item: 1, section: 1)),
            .insertItem(indexPath: IndexPath(item: 2, section: 1)),
        ]
        let changes = DataBatchUpdate(layoutData: layoutData, updateItems: updates)
        let results: [IndexPath: IndexPath?] = [
            IndexPath(item: 0, section: 0): IndexPath(item: 0, section: 0),
            IndexPath(item: 1, section: 0): nil,
            IndexPath(item: 2, section: 0): IndexPath(item: 2, section: 0),
            IndexPath(item: 3, section: 0): nil,
            IndexPath(item: 4, section: 0): IndexPath(item: 4, section: 0),
            
            IndexPath(item: 0, section: 1): nil,
            IndexPath(item: 1, section: 1): nil,
            IndexPath(item: 2, section: 1): nil,
            
            IndexPath(item: 0, section: 2): IndexPath(item: 0, section: 2),
            IndexPath(item: 1, section: 2): IndexPath(item: 1, section: 2),
            IndexPath(item: 2, section: 2): IndexPath(item: 2, section: 2),
        ]
        
        for indexPath in layoutData.indexPaths(startIndex: 0, endIndex: layoutData.itemsCount) {
            XCTAssertEqual(changes.indexPathAfterUpdate(for: indexPath), results[indexPath])
        }
        
    }
 
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
