//
//  LayoutModel.swift
//  ModelBasedCollectionView
//
//  Created by Matteo Ludwig on 18.07.23.
//

import UIKit


protocol LayoutModel {
    
    var contentSize: CGSize { get }
    
    func layoutAttributes(in rect: CGRect) -> [LayoutAttributes]
    
    func layoutAttributes(forItemAt indexPath: IndexPath) -> LayoutAttributes?
    func initialLayoutAttributes(forInsertedItemAt indexPath: IndexPath) -> LayoutAttributes?
    func finalLayoutAttributes(forDeletedItemAt indexPath: IndexPath) -> LayoutAttributes?
    
    func layoutAttributes(forSupplementaryViewAt indexPath: IndexPath) -> LayoutAttributes?
}

extension LayoutModel {
    func initialLayoutAttributes(forInsertedItemAt indexPath: IndexPath) -> LayoutAttributes? {
        return layoutAttributes(forItemAt: indexPath)
    }
    
    func finalLayoutAttributes(forDeletedItemAt indexPath: IndexPath) -> LayoutAttributes? {
        return layoutAttributes(forItemAt: indexPath)
    }
}
