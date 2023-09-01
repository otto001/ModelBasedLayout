//
//  LayoutModel.swift
//  ModelBasedCollectionView
//
//  Created by Matteo Ludwig on 18.07.23.
//

import UIKit


public protocol LayoutModel {
    
    var contentSize: CGSize { get }
    
    func transitionAnimation(forItemAt indexPair: IndexPair) -> TransitionAnimation
    func transitionAnimation(forSupplementaryViewOfKind elementKind: String, at indexPair: IndexPair) -> TransitionAnimation
    
    func items(in rect: CGRect) -> [Item]?
    
    func layoutAttributes(forItemAt indexPair: IndexPair) -> LayoutAttributes?
    func initialLayoutAttributes(forInsertedItemAt indexPair: IndexPair) -> LayoutAttributes?
    func finalLayoutAttributes(forDeletedItemAt indexPair: IndexPair) -> LayoutAttributes?
    
    func layoutAttributes(forHeaderOfSection section: Int) -> LayoutAttributes?
    
    func layoutAttributes(forAdditionalSupplementaryViewOfKind elementKind: String, at indexPair: IndexPair) -> LayoutAttributes?
    func initialLayoutAttributes(forAdditionalInsertedSupplementaryViewOfKind elementKind: String, at indexPair: IndexPair) -> LayoutAttributes?
    func finalLayoutAttributes(forAdditionalDeletedSupplementaryViewOfKind elementKind: String, at indexPair: IndexPair) -> LayoutAttributes?
}

public extension LayoutModel {
    
    func transitionAnimation(forItemAt indexPair: IndexPair) -> TransitionAnimation {
        return .opacity
    }
    
    func transitionAnimation(forSupplementaryViewOfKind elementKind: String, at indexPair: IndexPair) -> TransitionAnimation {
        return .opacity
    }
    
    func items(in rect: CGRect) -> [Item]? {
        return nil
    }
    
    func initialLayoutAttributes(forInsertedItemAt indexPair: IndexPair) -> LayoutAttributes? {
        return nil
    }
    
    func finalLayoutAttributes(forDeletedItemAt indexPair: IndexPair) -> LayoutAttributes? {
        return nil
    }
    
    func layoutAttributes(forHeaderOfSection section: Int) -> LayoutAttributes? {
        return nil
    }
    
    func layoutAttributes(forAdditionalSupplementaryViewOfKind elementKind: String, at indexPair: IndexPair) -> LayoutAttributes? {
        return nil
    }
    
    func initialLayoutAttributes(forAdditionalInsertedSupplementaryViewOfKind elementKind: String, at indexPair: IndexPair) -> LayoutAttributes? {
        return nil
    }
    
    func finalLayoutAttributes(forAdditionalDeletedSupplementaryViewOfKind elementKind: String, at indexPair: IndexPair) -> LayoutAttributes? {
        return nil
    }
}
