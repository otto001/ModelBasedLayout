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
    func transitionAnimation(forSupplementaryViewOfKind elementKind: String, at indexPath: IndexPath) -> TransitionAnimation
    
    func items(in rect: CGRect) -> [Item]?
    
    func layoutAttributes(forItemAt indexPath: IndexPath) -> LayoutAttributes?
    func initialLayoutAttributes(forInsertedItemAt indexPath: IndexPath) -> LayoutAttributes?
    func finalLayoutAttributes(forDeletedItemAt indexPath: IndexPath) -> LayoutAttributes?
    
    func layoutAttributes(forHeaderOfSection section: Int) -> LayoutAttributes?
    
    func layoutAttributes(forAdditionalSupplementaryViewOfKind elementKind: String, at indexPath: IndexPath) -> LayoutAttributes?
    func initialLayoutAttributes(forAdditionalInsertedSupplementaryViewOfKind elementKind: String, at indexPath: IndexPath) -> LayoutAttributes?
    func finalLayoutAttributes(forAdditionalDeletedSupplementaryViewOfKind elementKind: String, at indexPath: IndexPath) -> LayoutAttributes?
}

public extension LayoutModel {
    
    func transitionAnimation(forItemAt indexPath: IndexPath) -> TransitionAnimation {
        return .opacity
    }
    
    func transitionAnimation(forSupplementaryViewOfKind elementKind: String, at indexPath: IndexPath) -> TransitionAnimation {
        return .opacity
    }
    
    func items(in rect: CGRect) -> [Item]? {
        return nil
    }
    
    func initialLayoutAttributes(forInsertedItemAt indexPath: IndexPath) -> LayoutAttributes? {
        return nil
    }
    
    func finalLayoutAttributes(forDeletedItemAt indexPath: IndexPath) -> LayoutAttributes? {
        return nil
    }
    
    func layoutAttributes(forHeaderOfSection section: Int) -> LayoutAttributes? {
        return nil
    }
    
    func layoutAttributes(forAdditionalSupplementaryViewOfKind elementKind: String, at indexPath: IndexPath) -> LayoutAttributes? {
        return nil
    }
    
    func initialLayoutAttributes(forAdditionalInsertedSupplementaryViewOfKind elementKind: String, at indexPath: IndexPath) -> LayoutAttributes? {
        return nil
    }
    
    func finalLayoutAttributes(forAdditionalDeletedSupplementaryViewOfKind elementKind: String, at indexPath: IndexPath) -> LayoutAttributes? {
        return nil
    }
}
