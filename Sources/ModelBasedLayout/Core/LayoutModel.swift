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
    
    func layoutAttributes(for element: Element) -> LayoutAttributes?
    func layoutAttributes(for element: Element, frame: AnimationFrame) -> LayoutAttributes?
}

public extension LayoutModel {
    
    func transitionAnimation(for element: Element, transition: ElementTransition) -> TransitionAnimation {
        return .opacity
    }
    
    func layoutAttributes(for element: Element, frame: AnimationFrame) -> LayoutAttributes? {
        return layoutAttributes(for: element)
    }
}
