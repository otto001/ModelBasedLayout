//
//  DataUpdate.swift
//  ModelBasedCollectionView
//
//  Created by Matteo Ludwig on 18.07.23.
//

import UIKit


enum DataUpdate: Hashable, Comparable {
    case insertItem(indexPair: IndexPair)
    case insertSection(sectionIndex: Int)
    
    case reloadItem(indexPairBeforeUpdate: IndexPair, indexPairAfterUpdate: IndexPair)
    case reloadSection(sectionIndexBeforeUpdate: Int, sectionIndexAfterUpdate: Int)
    
    case deleteItem(indexPair: IndexPair)
    case deleteSection(sectionIndex: Int)
    
    private var sortPriority: Int {
        switch self {
        case .insertItem:
            return 5
        case .reloadItem:
            return 4
        case .reloadSection:
            return 3
        case .deleteItem:
            return 2
            
        case .insertSection:
            return 1
        case .deleteSection:
            return 0
        }
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.sortPriority < rhs.sortPriority {
            return true
        } else if lhs.sortPriority == rhs.sortPriority {
            switch (lhs, rhs) {
                
            case (.insertItem(let indexPairLhs), .insertItem(let indexPairRhs)):
                return indexPairLhs < indexPairRhs
                
            case (.insertSection(let sectionIndexLhs), .insertSection(let sectionIndexRhs)):
                return sectionIndexLhs < sectionIndexRhs
                
            case (.reloadItem(let indexPairLhs, _), .reloadItem(let indexPairRhs, _)):
                return indexPairLhs < indexPairRhs
                
            case (.reloadSection(let sectionIndexLhs, _), .reloadSection(let sectionIndexRhs, _)):
                return sectionIndexLhs < sectionIndexRhs
                
            case (.deleteItem(let indexPairLhs), .deleteItem(let indexPairRhs)):
                return indexPairLhs < indexPairRhs
                
            case (.deleteSection(let sectionIndexLhs), .deleteSection(let sectionIndexRhs)):
                return sectionIndexLhs < sectionIndexRhs
                
            default:
                fatalError("Should not happen")
            }
        } else {
            return false
        }
    }
    
    
    
    init?(_ updateItem: UICollectionViewUpdateItem) {
        switch updateItem.updateAction {
        case .delete:
            guard let indexPath = updateItem.indexPathBeforeUpdate else { return nil }
            
            if indexPath.item == NSNotFound {
                self = .deleteSection(sectionIndex: indexPath.section)
            } else {
                self = .deleteItem(indexPair: .init(indexPath))
            }
            
            
        case .reload:
            guard let indexPathBeforeUpdate = updateItem.indexPathBeforeUpdate,
                  let indexPathAfterUpdate = updateItem.indexPathAfterUpdate else { return nil }
            
            if indexPathBeforeUpdate.item == NSNotFound {
                self = .reloadSection(sectionIndexBeforeUpdate: indexPathBeforeUpdate.section, sectionIndexAfterUpdate: indexPathAfterUpdate.section)
            } else {
                self = .reloadItem(indexPairBeforeUpdate: .init(indexPathBeforeUpdate), indexPairAfterUpdate: .init(indexPathAfterUpdate))
            }
            
            
        case .insert:
            guard let indexPath = updateItem.indexPathAfterUpdate else { return nil }
            
            if indexPath.item == NSNotFound {
                self = .insertSection(sectionIndex: indexPath.section)
            } else {
                self = .insertItem(indexPair: .init(indexPath))
            }
            
            
        default:
            return nil
        }
    }
}
