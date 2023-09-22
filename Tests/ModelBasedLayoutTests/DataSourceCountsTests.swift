//
//  DataSourceCountsTests.swift
//  ModelBasedLayoutTests
//
//  Created by Matteo Ludwig on 18.07.23.
//

import XCTest
import UIKit
@testable import ModelBasedLayout


final class DataSourceCountsTests: XCTestCase {
    var rng = RandomNumberGeneratorWithSeed(seed: 666)
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSectionData() throws {
        
        let test = DataSourceCounts(sections: [100, 50, 25, 25])
        
        XCTAssertEqual(test.itemsCount, 200)
        XCTAssertEqual(test.numberOfSections, 4)
        
        XCTAssertEqual(test.sections[0].section, 0)
        XCTAssertEqual(test.sections[0].itemCount, 100)
        XCTAssertEqual(test.sections[0].firstItemIndex, 0)
        XCTAssertEqual(test.sections[0].firstItemIndexPair, IndexPair(item: 0, section: 0))
        XCTAssertEqual(test.sections[0].lastItemIndex, 99)
        XCTAssertEqual(test.sections[0].lastItemIndexPair, IndexPair(item: 99, section: 0))
        
        XCTAssertEqual(test.sections[1].section, 1)
        XCTAssertEqual(test.sections[1].itemCount, 50)
        XCTAssertEqual(test.sections[1].firstItemIndex, 100)
        XCTAssertEqual(test.sections[1].firstItemIndexPair, IndexPair(item: 0, section: 1))
        XCTAssertEqual(test.sections[1].lastItemIndex, 149)
        XCTAssertEqual(test.sections[1].lastItemIndexPair, IndexPair(item: 49, section: 1))
        
        XCTAssertEqual(test.sections[2].section, 2)
        XCTAssertEqual(test.sections[2].itemCount, 25)
        XCTAssertEqual(test.sections[2].firstItemIndex, 150)
        XCTAssertEqual(test.sections[2].firstItemIndexPair, IndexPair(item: 0, section: 2))
        XCTAssertEqual(test.sections[2].lastItemIndex, 174)
        XCTAssertEqual(test.sections[2].lastItemIndexPair, IndexPair(item: 24, section: 2))
        
        XCTAssertEqual(test.sections[3].section, 3)
        XCTAssertEqual(test.sections[3].itemCount, 25)
        XCTAssertEqual(test.sections[3].firstItemIndex, 175)
        XCTAssertEqual(test.sections[3].firstItemIndexPair, IndexPair(item: 0, section: 3))
        XCTAssertEqual(test.sections[3].lastItemIndex, 199)
        XCTAssertEqual(test.sections[3].lastItemIndexPair, IndexPair(item: 24, section: 3))
        
        
        XCTAssertEqual(test.indexPair(for: 0), IndexPair(item: 0, section: 0))
        XCTAssertEqual(test.indexPair(for: 50), IndexPair(item: 50, section: 0))
        XCTAssertEqual(test.indexPair(for: 99), IndexPair(item: 99, section: 0))
        XCTAssertEqual(test.indexPair(for: 100), IndexPair(item: 0, section: 1))
        XCTAssertEqual(test.indexPair(for: 101), IndexPair(item: 1, section: 1))
        XCTAssertEqual(test.indexPair(for: 149), IndexPair(item: 49, section: 1))
        XCTAssertEqual(test.indexPair(for: 150), IndexPair(item: 0, section: 2))
        XCTAssertEqual(test.indexPair(for: 174), IndexPair(item: 24, section: 2))
        XCTAssertEqual(test.indexPair(for: 175), IndexPair(item: 0, section: 3))
        XCTAssertEqual(test.indexPair(for: 199), IndexPair(item: 24, section: 3))
        
        
        XCTAssertEqual(test.index(of: IndexPair(item: 0, section: 0)), 0)
        XCTAssertEqual(test.index(of: IndexPair(item: 50, section: 0)), 50)
        XCTAssertEqual(test.index(of: IndexPair(item: 99, section: 0)), 99)
        XCTAssertEqual(test.index(of: IndexPair(item: 0, section: 1)), 100)
        XCTAssertEqual(test.index(of: IndexPair(item: 1, section: 1)), 101)
        XCTAssertEqual(test.index(of: IndexPair(item: 49, section: 1)), 149)
        XCTAssertEqual(test.index(of: IndexPair(item: 0, section: 2)), 150)
        XCTAssertEqual(test.index(of: IndexPair(item: 24, section: 2)), 174)
        XCTAssertEqual(test.index(of: IndexPair(item: 0, section: 3)), 175)
        XCTAssertEqual(test.index(of: IndexPair(item: 24, section: 3)), 199)
        
        
        XCTAssertEqual(test.indexPairs(for: 0..<3), [IndexPair(item: 0, section: 0), IndexPair(item: 1, section: 0), IndexPair(item: 2, section: 0)])
        XCTAssertEqual(test.indexPairs(for: 98...101), [IndexPair(item: 98, section: 0), IndexPair(item: 99, section: 0), IndexPair(item: 0, section: 1), IndexPair(item: 1, section: 1)])
        
        var result = (0..<100).map { IndexPair(item: $0, section: 0)}
        result.append(contentsOf: (0..<50).map { IndexPair(item: $0, section: 1)})
        result.append(contentsOf: (0..<10).map { IndexPair(item: $0, section: 2)})
        
        XCTAssertEqual(test.indexPairs(for: 0..<160), result)
        XCTAssertEqual(test.indexPairs(for: 0...159), result)
        
        var allIndexPairs = (0..<100).map { IndexPair(item: $0, section: 0)}
        allIndexPairs.append(contentsOf: (0..<50).map { IndexPair(item: $0, section: 1)})
        allIndexPairs.append(contentsOf: (0..<25).map { IndexPair(item: $0, section: 2)})
        allIndexPairs.append(contentsOf: (0..<25).map { IndexPair(item: $0, section: 3)})
        
        XCTAssertEqual(test.indexPairs(for: 0..<test.itemsCount), allIndexPairs)
        
        for i in 0..<allIndexPairs.count-1 {
            XCTAssertEqual(test.indexPair(after: allIndexPairs[i]), allIndexPairs[i + 1])
        }
        XCTAssertEqual(test.indexPair(after: allIndexPairs[199]), nil)
        
        XCTAssertEqual(test.indexPair(before: allIndexPairs[0]), nil)
        for i in 1..<allIndexPairs.count {
            XCTAssertEqual(test.indexPair(before: allIndexPairs[i]), allIndexPairs[i - 1])
        }
    }
    
    class TestDataSource: NSObject, UICollectionViewDataSource {
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            return 4
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return [100, 50, 25, 25][section]
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            return UICollectionViewCell(frame: .zero)
        }
    }
    
    func testFromCollectionView() {
        let dataSource = TestDataSource()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.dataSource = dataSource
        
        let test = DataSourceCounts(collectionView: collectionView)
        
        XCTAssertEqual(test.itemsCount, 200)
        XCTAssertEqual(test.numberOfSections, 4)
        
        XCTAssertEqual(test.sections[0].section, 0)
        XCTAssertEqual(test.sections[0].itemCount, 100)
        XCTAssertEqual(test.sections[0].firstItemIndex, 0)
        XCTAssertEqual(test.sections[0].firstItemIndexPair, IndexPair(item: 0, section: 0))
        XCTAssertEqual(test.sections[0].lastItemIndex, 99)
        XCTAssertEqual(test.sections[0].lastItemIndexPair, IndexPair(item: 99, section: 0))
        
        XCTAssertEqual(test.sections[1].section, 1)
        XCTAssertEqual(test.sections[1].itemCount, 50)
        XCTAssertEqual(test.sections[1].firstItemIndex, 100)
        XCTAssertEqual(test.sections[1].firstItemIndexPair, IndexPair(item: 0, section: 1))
        XCTAssertEqual(test.sections[1].lastItemIndex, 149)
        XCTAssertEqual(test.sections[1].lastItemIndexPair, IndexPair(item: 49, section: 1))
        
        XCTAssertEqual(test.sections[2].section, 2)
        XCTAssertEqual(test.sections[2].itemCount, 25)
        XCTAssertEqual(test.sections[2].firstItemIndex, 150)
        XCTAssertEqual(test.sections[2].firstItemIndexPair, IndexPair(item: 0, section: 2))
        XCTAssertEqual(test.sections[2].lastItemIndex, 174)
        XCTAssertEqual(test.sections[2].lastItemIndexPair, IndexPair(item: 24, section: 2))
        
        XCTAssertEqual(test.sections[3].section, 3)
        XCTAssertEqual(test.sections[3].itemCount, 25)
        XCTAssertEqual(test.sections[3].firstItemIndex, 175)
        XCTAssertEqual(test.sections[3].firstItemIndexPair, IndexPair(item: 0, section: 3))
        XCTAssertEqual(test.sections[3].lastItemIndex, 199)
        XCTAssertEqual(test.sections[3].lastItemIndexPair, IndexPair(item: 24, section: 3))
    }
    
    func testIndexPairRangePerformance() {
        let sections: [Int] = (0..<1_000).map {_ in
            return 1000
        }
        let test = DataSourceCounts(sections: sections)
        
        self.measure {
            _ = test.indexPairs(for: 0..<test.itemsCount)
        }
    }
    
    func testIndexPairForIndexPerformance() {
        let sections: [Int] = (0..<1_000).map {_ in
            return 1000
        }
        let test = DataSourceCounts(sections: sections)
        
        self.measure {
            for _ in 0..<100_000 {
                let index = Int.random(in: 0..<test.itemsCount, using: &rng)
                _ = test.indexPair(for: index)
            }
        }
    }
}
