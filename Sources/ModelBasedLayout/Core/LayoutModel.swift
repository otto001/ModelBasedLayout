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
    
    func contentOffsetAnchor(in rect: CGRect) -> Element?
    
    func adjustForSelfSizing(element: Element, preferredSize: CGSize)
    
}

public extension LayoutModel {
    
    func transitionAnimation(for element: Element, transition: ElementTransition) -> TransitionAnimation {
        return .opacity
    }
    
    func layoutAttributes(for element: Element, frame: AnimationFrame) -> LayoutAttributes? {
        return layoutAttributes(for: element)
    }
    
    func contentOffsetAnchor(in rect: CGRect) -> Element? {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        return elements(in: rect)
            .filter { $0.elementKind == .cell }
            .compactMap { layoutAttributes(for: $0) }
            .map {
                ($0.element, ($0.frame.center - center).length)
            }
            .min {
                $0.1 < $1.1
            }?.0
    }
    
    func adjustForSelfSizing(element: Element, preferredSize: CGSize) {
    }
    
}
