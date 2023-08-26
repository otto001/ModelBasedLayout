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
    
    func items(in rect: CGRect) -> [Item]?
    
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
    
    func items(in rect: CGRect) -> [Item]? {
        return nil
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
