//
//  LayoutModel.swift
//  ModelBasedLayout
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
    
    func contentOffsetAnchor(in rect: CGRect) -> IndexPair?
}

public extension LayoutModel {
    
    func transitionAnimation(for element: Element, transition: ElementTransition) -> TransitionAnimation {
        return .opacity
    }
    
    func layoutAttributes(for element: Element, frame: AnimationFrame) -> LayoutAttributes? {
        return layoutAttributes(for: element)
    }
    
    func contentOffsetAnchor(in rect: CGRect) -> IndexPair? {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        return elements(in: rect)
            .filter { $0.elementKind == .cell }
            .compactMap { layoutAttributes(for: $0) }
            .map {
                ($0.indexPair, ($0.frame.center - center).length)
            }
            .min{ (a, b) in
                a.1 < b.1
            }?.0
    }
}
