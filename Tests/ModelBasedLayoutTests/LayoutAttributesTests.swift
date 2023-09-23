//
//  LayoutAttributesTests.swift
//  
//
//  Created by Matteo Ludwig on 22.09.23.
//


import XCTest
import UIKit
@testable import ModelBasedLayout


final class LayoutAttributesTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFrame() throws {

        var test = LayoutAttributes(element: .cell(IndexPair(item: 0, section: 0)))
        test.frame = CGRect(x: -100, y: -25, width: 200, height: 50)
        test.transform = .init(rotationAngle: .pi/2)
        
        XCTAssertEqual(test.transform, .init(rotationAngle: .pi/2))
        
        XCTAssertEqual(test.frame.minX.rounded(), -25)
        XCTAssertEqual(test.frame.maxX.rounded(), 25)
        XCTAssertEqual(test.frame.minY.rounded(), -100)
        XCTAssertEqual(test.frame.maxY.rounded(), 100)
        
        XCTAssertEqual(test.bounds.minX.rounded(), 0)
        XCTAssertEqual(test.bounds.maxX.rounded(), 200)
        XCTAssertEqual(test.bounds.minY.rounded(), 0)
        XCTAssertEqual(test.bounds.maxY.rounded(), 50)
    }
    
    func testForLayout() throws {
        
        var test = LayoutAttributes(element: .cell(IndexPair(item: 0, section: 0)))
        test.isHidden = true
        test.alpha = 0.5
        test.zIndex = 99
        test.frame = CGRect(x: 10, y: 20, width: 200, height: 50)
        test.transform = .init(translationX: 100, y: 0)
        
        let convertedTest = test.forLayout()
        
        XCTAssertEqual(convertedTest.transform, .init(translationX: 100, y: 0))
        XCTAssertEqual(convertedTest.frame, CGRect(x: 110, y: 20, width: 200, height: 50))
        XCTAssertEqual(convertedTest.alpha, 0.5)
        XCTAssertEqual(convertedTest.isHidden, true)
        XCTAssertEqual(convertedTest.zIndex, 99)
    }
}
