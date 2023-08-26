//
//  LayoutModel.swift
//  ModelBasedCollectionView
//
//  Created by Matteo Ludwig on 18.07.23.
//

import UIKit


public protocol LayoutModel {
    
    var contentSize: CGSize { get }
    
    func transitionAnimation(forItemAt indexPath: IndexPath) -> TransitionAnimation
    func transitionAnimation(forSupplementaryViewAt indexPath: IndexPath, with elementKind: String) -> TransitionAnimation
    
    func layoutAttributes(in rect: CGRect, for dataSourceCounts: DataSourceCounts) -> [LayoutAttributes]
    
    func layoutAttributes(forItemAt indexPath: IndexPath) -> LayoutAttributes?
    func initialLayoutAttributes(forInsertedItemAt indexPath: IndexPath) -> LayoutAttributes?
    func finalLayoutAttributes(forDeletedItemAt indexPath: IndexPath) -> LayoutAttributes?
    
    func layoutAttributes(forHeaderOfSection section: Int) -> LayoutAttributes?
    var sectionHeadersSticky: Bool { get }
    
    func layoutAttributes(forAdditionalSupplementaryViewAt indexPath: IndexPath, with elementKind: String) -> LayoutAttributes?
    func initialLayoutAttributes(forInsertedSupplementaryViewAt indexPath: IndexPath, with elementKind: String) -> LayoutAttributes?
    func finalLayoutAttributes(forDeletedSupplementaryViewAt indexPath: IndexPath, with elementKind: String) -> LayoutAttributes?
}

public extension LayoutModel {
    
    func transitionAnimation(forItemAt indexPath: IndexPath) -> TransitionAnimation {
        return .opacity
    }
    
    func transitionAnimation(forSupplementaryViewAt indexPath: IndexPath, with elementKind: String) -> TransitionAnimation {
        return .opacity
    }
    
    func layoutAttributes(in rect: CGRect, for dataSourceCounts: DataSourceCounts) -> [LayoutAttributes] {
        // TODO: Optimize!
        
        let indexPaths = (0..<dataSourceCounts.itemsCount).lazy.map { dataSourceCounts.indexPath(for: $0) }
        
        let cells = indexPaths.map { layoutAttributes(forItemAt: $0) }
        let cellRange = cells.binarySearchRange { attrs in
            if attrs!.frame.intersects(rect) {
                return .equal
            } else if attrs!.frame.maxY < rect.minY || attrs!.frame.maxX < rect.minX {
                return .before
            } else {
                return .after
            }
        }
        
        guard let cellRange = cellRange else { return [] }
        
        var results = Array(cells[cellRange].compactMap {$0})
        
        let firstVisibleSection = 0
        //let firstVisibleSection = cells[cellRange.lowerBound]!.indexPath.section
        let lastVisibleSection = cells[cellRange.upperBound]!.indexPath.section
        
        let headers = (firstVisibleSection...lastVisibleSection)
            .compactMap { layoutAttributes(forHeaderOfSection: $0)}
            .filter { $0.frame.intersects(rect) }
        results.append(contentsOf: headers)
        
        return results
    }
    
    func initialLayoutAttributes(forInsertedItemAt indexPath: IndexPath) -> LayoutAttributes? {
        return layoutAttributes(forItemAt: indexPath)
    }
    
    func finalLayoutAttributes(forDeletedItemAt indexPath: IndexPath) -> LayoutAttributes? {
        return layoutAttributes(forItemAt: indexPath)
    }
    
    func layoutAttributes(forHeaderOfSection section: Int) -> LayoutAttributes? {
        return nil
    }
    
    var sectionHeadersSticky: Bool { false }
    
    func initialLayoutAttributes(forInsertedSupplementaryViewAt indexPath: IndexPath, with elementKind: String) -> LayoutAttributes? {
        return layoutAttributes(forSupplementaryViewAt: indexPath, with: elementKind)
    }
    
    func layoutAttributes(forAdditionalSupplementaryViewAt indexPath: IndexPath, with elementKind: String) -> LayoutAttributes? {
        return nil
    }
    
    func finalLayoutAttributes(forDeletedSupplementaryViewAt indexPath: IndexPath, with elementKind: String) -> LayoutAttributes? {
        return layoutAttributes(forSupplementaryViewAt: indexPath, with: elementKind)
    }
}


internal extension LayoutModel {
    func layoutAttributes(forSupplementaryViewAt indexPath: IndexPath, with elementKind: String) -> LayoutAttributes? {
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            return self.layoutAttributes(forHeaderOfSection: indexPath.section)
        default:
            return self.layoutAttributes(forSupplementaryViewAt: indexPath, with: elementKind)
        }
    }
}
