//
//  DataUpdate.swift
//  ModelBasedLayout
//
//  Created by Matteo Ludwig on 18.07.23.
//

import Foundation


enum DataUpdate: Hashable {
    case insertItem(indexPair: IndexPair)
    case insertSection(sectionIndex: Int)
    
    case reloadItem(indexPairBeforeUpdate: IndexPair, indexPairAfterUpdate: IndexPair)
    case reloadSection(sectionIndexBeforeUpdate: Int, sectionIndexAfterUpdate: Int)
    
    case moveItem(indexPairBeforeUpdate: IndexPair, indexPairAfterUpdate: IndexPair)
    case moveSection(sectionIndexBeforeUpdate: Int, sectionIndexAfterUpdate: Int)
    
    case deleteItem(indexPair: IndexPair)
    case deleteSection(sectionIndex: Int)
    
    
    init?(_ updateItem: NativeCollectionViewUpdateItem) {
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
            
            
        case .move:
            guard let indexPathBeforeUpdate = updateItem.indexPathBeforeUpdate,
                  let indexPathAfterUpdate = updateItem.indexPathAfterUpdate else { return nil }
            
            if indexPathBeforeUpdate.item == NSNotFound {
                self = .moveSection(sectionIndexBeforeUpdate: indexPathBeforeUpdate.section, sectionIndexAfterUpdate: indexPathAfterUpdate.section)
            } else {
                self = .moveItem(indexPairBeforeUpdate: .init(indexPathBeforeUpdate), indexPairAfterUpdate: .init(indexPathAfterUpdate))
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
