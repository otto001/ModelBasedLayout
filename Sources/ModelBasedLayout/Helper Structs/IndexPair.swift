//
//  IndexPair.swift
//  
//
//  Created by Matteo Ludwig on 01.09.23.
//

import Foundation


public struct IndexPair: Hashable, Equatable {
    
    public var item: Int
    public var section: Int
    
    public init(item: Int, section: Int) {
        self.item = item
        self.section = section
    }
    
    public init(_ indexPath: IndexPath) {
        self.item = indexPath.item
        self.section = indexPath.section
    }
    
    public var indexPath: IndexPath {
        return IndexPath(item: item, section: section)
    }
}

extension IndexPair: Comparable {
    public static func < (lhs: IndexPair, rhs: IndexPair) -> Bool {
        lhs.section < rhs.section || lhs.section == rhs.section && lhs.item < rhs.item
    }
}

extension IndexPair: CustomStringConvertible {
    public var description: String {
        "\(section).\(item)"
    }
}

