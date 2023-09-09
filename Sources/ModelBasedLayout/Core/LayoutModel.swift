//
//  LayoutModel.swift
//  ModelBasedCollectionView
//
//  Created by Matteo Ludwig on 18.07.23.
//

import UIKit


public protocol LayoutModel {
    
    var contentSize: CGSize { get }
    
    func transitionAnimation(for element: Element, transition: ElementTransition) -> TransitionAnimation
    
    func elements(in rect: CGRect) -> [Element]
    
    func layoutAttributes(forCellAt indexPair: IndexPair) -> LayoutAttributes?
    func initialLayoutAttributes(forInsertedItemAt indexPair: IndexPair) -> LayoutAttributes?
    func finalLayoutAttributes(forDeletedItemAt indexPair: IndexPair) -> LayoutAttributes?
    
    func layoutAttributes(forHeaderOfSection section: Int) -> LayoutAttributes?
    func layoutAttributes(forFooterOfSection section: Int) -> LayoutAttributes?
    
    func layoutAttributes(forAdditionalSupplementaryViewOfKind elementKind: String, at indexPair: IndexPair) -> LayoutAttributes?
    func initialLayoutAttributes(forAdditionalInsertedSupplementaryViewOfKind elementKind: String, at indexPair: IndexPair, isReloading: Bool) -> LayoutAttributes?
    func finalLayoutAttributes(forAdditionalDeletedSupplementaryViewOfKind elementKind: String, at indexPair: IndexPair, isReloading: Bool) -> LayoutAttributes?
}

public extension LayoutModel {
    
    func transitionAnimation(for element: Element, transition: ElementTransition) -> TransitionAnimation {
        return .opacity
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
    
    func layoutAttributes(forFooterOfSection section: Int) -> LayoutAttributes? {
        return nil
    }
    
    func layoutAttributes(forAdditionalSupplementaryViewOfKind elementKind: String, at indexPair: IndexPair) -> LayoutAttributes? {
        return nil
    }
    
    func initialLayoutAttributes(forAdditionalInsertedSupplementaryViewOfKind elementKind: String, at indexPair: IndexPair, isReloading: Bool) -> LayoutAttributes? {
        return nil
    }
    
    func finalLayoutAttributes(forAdditionalDeletedSupplementaryViewOfKind elementKind: String, at indexPair: IndexPair, isReloading: Bool) -> LayoutAttributes? {
        return nil
    }
}
