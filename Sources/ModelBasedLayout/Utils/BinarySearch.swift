//
//  BinarySearch.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 11.03.23.
//

import Foundation


extension RandomAccessCollection where Element: Comparable & Equatable, Index: BinaryInteger {
    
    /// Perform a binary search on the Collection.
    /// Assumes the collection is sorted by the given sortedBy closure. If the collection is not sorted in a fashion equivalent to the sortedBy closure, the alogrithm will return unreliable results.
    /// - Parameter element: The element to search for.
    /// - Parameter sortedBy: The comparison closure by which the collection is sorted.
    /// - Returns: The index of the given element, if the element is contained in the collection. Otherwise, nil is returned.
    /// - Complexity: O(log n)
    func binarySearch(for element: Element, sortedBy: (_ lhs: Element, _ rhs: Element) -> Bool) -> Index? {
        guard !self.isEmpty else { return nil }
        
        var first = self.startIndex
        var last = self.endIndex - 1

        var center = (first + last)/2
        
        while self[center] != element {
            if sortedBy(element, self[center]) {
                last = center - 1
            } else {
                first = center + 1
            }
            guard first <= last else {
                return nil
            }
            center = (first + last)/2
        }
        
        return center
    }
}

enum BinarySearchComparisonResult {
    /// The searched element is before the current one.
    case before
    
    /// The element is equal to the searched for element. Terminates the binary search.
    case equal
    
    /// The searched element is after the current one.
    case after
}

extension RandomAccessCollection where Index: BinaryInteger {
    /// Perform a binary search on the Collection using a custom comparison closure.
    ///
    /// - Parameter comparision: A closure, that given an element, returns a BinarySearchComparisonResult indicating where the search should be continued.
    /// - Returns: The index of the first element for which the comparison function returned equal. If no equal element is found, nil is returned.
    /// - Complexity: O(log n)
    /// - Note: Binary search requires the collection to be sorted in some fashion. How exactly is not important to this function, but the comparison closure must return consistent and acurate information for the algorithm to succeed.
    func binarySearch(comparision: @escaping (_ element: Element) -> BinarySearchComparisonResult) -> Index? {
        guard !self.isEmpty else { return nil }
        
        var first = self.startIndex
        var last = self.endIndex - 1
        
        var center = (first + last)/2
        
        while true {
            
            switch comparision(self[center]) {
            case .equal:
                return center
            case .before:
                last = center - 1
            case .after:
                first = center + 1
            }
            
            guard first <= last else {
                return nil
            }
            center = (first + last)/2
        }
        
        fatalError("binarySearch error, please check your comparison closure")
    }
}
