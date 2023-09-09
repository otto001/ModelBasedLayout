//
//  LayoutController.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import UIKit


class LayoutController<ModelType: LayoutModel> {
    
    private let container: LayoutContainer<ModelType>
    
    private var prepareActions: PrepareActions = []
    private var dataChange: DataBatchUpdate? = nil
    
    private var lastInvalidatedBounds: CGRect? = nil
    
    private(set) var boundsProvider: () -> CGRect
    
    init(_ model: @escaping (_ dataSourceCounts: DataSourceCounts, _ geometryInfo: GeometryInfo) -> ModelType,
         dataSourceCounts: @escaping () -> DataSourceCounts,
         geometryInfo: @escaping () -> GeometryInfo,
         boundsProvider: @escaping () -> CGRect) {
        
        self.container = .init(modelProvider: model, dataSourceCountsProvider: dataSourceCounts, geometryInfoProvider: geometryInfo, boundsProvider: boundsProvider)
        
        self.boundsProvider = boundsProvider
    }
    
    internal func layoutModel(_ state: LayoutState) -> ModelType? {
        self.container.layout(state)?.model
    }
    
    private func dataSourceCounts(_ state: LayoutState) -> DataSourceCounts? {
        self.container.layout(state)?.dataSourceCounts
    }
    
    private func geometryInfo(_ state: LayoutState) -> GeometryInfo? {
        self.container.layout(state)?.geometryInfo
    }
    
    private func stickyController(_ state: LayoutState) -> StickyController? {
        self.container.layout(state)?.stickyController
    }
    
    func needsToReplaceModel() {
        self.prepareActions.insert(.replaceModel)
    }
    
    var collectionViewContentSize: CGSize {
        if let model = self.layoutModel(.afterUpdate) {
            return model.contentSize
        }
        return .zero
    }
    
    // MARK: Prepare
    func prepare() {
        if self.layoutModel(.afterUpdate) == nil || prepareActions.contains(.replaceModel) {
            self.container.pushNewLayout()
        }
        
        assert(self.stickyController(.afterUpdate)?.isBeingTransitionOut != true)
        //self.stickyController(.afterUpdate)?.unfreezeLayoutAttributes()
        
        self.prepareActions = []
    }
    
    func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        guard !updateItems.isEmpty else { return }
        self.dataChange = DataBatchUpdate(dataSourceCounts: self.dataSourceCounts(.beforeUpdate)!, updateItems: updateItems)
    }
    
    func finalize() {
        self.container.clearLayoutBefore()
        self.dataChange = nil
    }
    
    
    private func getContentOffsetAdjustment(contentSizeBefore: CGSize, geometryBefore: GeometryInfo,
                                            contentSizeAfter: CGSize, geometryAfter: GeometryInfo,
                                            contentOffset: CGPoint) -> CGSize {
        
        guard contentSizeBefore > .zero && contentSizeAfter > .zero  else { return .zero }
        
        let currentContentOffset = contentOffset.cgSize
        
        
        let halfBoundsSizeBefore = (geometryBefore.viewSize/2)
        let halfBoundsSizeAfter = (geometryAfter.viewSize/2)
        
        let insetBefore = CGSize(width: geometryBefore.adjustedContentInset.left, height: geometryBefore.adjustedContentInset.top)
        let insetAfter = CGSize(width: geometryAfter.adjustedContentInset.left, height: geometryAfter.adjustedContentInset.top)
        let insetDiff = insetBefore - insetAfter
        
        let scrollRatio = (currentContentOffset + halfBoundsSizeBefore - insetDiff) / contentSizeBefore
        
        return (scrollRatio * contentSizeAfter - halfBoundsSizeAfter) - currentContentOffset
    }
    
    private func usesStickyViews() -> Bool {
        self.stickyController(.afterUpdate)?.usesStickyViews ?? false
    }
    
    // MARK: Invalidation
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if newBounds.size != self.geometryInfo(.afterUpdate)?.viewSize {
            return true
        }
        // TODO: move this logic into the sticky controller
        if self.usesStickyViews() && self.lastInvalidatedBounds != newBounds {
            self.lastInvalidatedBounds = newBounds
            return true
        }
        return false
    }
    
    func configureInvalidationContext(forBoundsChange newBounds: CGRect, with context: UICollectionViewLayoutInvalidationContext) {
        if let geometryBefore = self.geometryInfo(.afterUpdate),
           newBounds.size != geometryBefore.viewSize,
           let currentModel = self.layoutModel(.afterUpdate),
           context.contentOffsetAdjustment == .zero {
            // viewSize change
            
            
            
            let newLayout = self.container.makeNewLayout(forNewBounds: newBounds)
            
            context.contentSizeAdjustment = newLayout.model.contentSize - currentModel.contentSize
            context.contentOffsetAdjustment = self.getContentOffsetAdjustment(contentSizeBefore: currentModel.contentSize,
                                                                              geometryBefore: geometryBefore,
                                                                              contentSizeAfter: newLayout.model.contentSize,
                                                                              geometryAfter: newLayout.geometryInfo,
                                                                              contentOffset: boundsProvider().origin).cgPoint
            
        }
        
        if self.usesStickyViews(), let stickyController = self.stickyController(.afterUpdate) {
            stickyController.configureInvalidationContext(forBoundsChange: newBounds, with: context)
            
        }
    }
    
    func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        if context.invalidateDataSourceCounts || context.invalidateEverything || context.contentSizeAdjustment != .zero  || context.contentOffsetAdjustment != .zero  {
            self.needsToReplaceModel()
        }
        
        self.stickyController(.afterUpdate)?.invalidateVisibleBounds()
    }
    
    // MARK: Animations
    func transitionAnimation(for element: Element, transition: ElementTransition, state: LayoutState) -> TransitionAnimation {
        self.layoutModel(state)?.transitionAnimation(for: element, transition: transition) ?? .none
    }
    
    // MARK: Rect
    func layoutAttributesForElements(in rect: CGRect) -> [LayoutAttributes]? {
        let items = self.layoutModel(.afterUpdate)!.elements(in: rect)
        return items.compactMap { (element: Element) -> LayoutAttributes? in
            self.layoutAttributes(for: element)
        }
        
    }
    
    
    // MARK: Layout Attributes
    func layoutAttributes(for element: Element) -> LayoutAttributes? {
        switch element.elementKind {
        case .cell:
            return self.layoutAttributes(forCellAt: element.indexPair)
        case .header, .footer, .additionalSupplementaryView:
            return self.layoutAttributes(forSupplementaryElement: element)
        case .decorativeView:
            return nil
        }
    }
    
    // MARK: Cells
    
    func layoutAttributes(forAppearingItemAt indexPair: IndexPair) -> LayoutAttributes? {
        
        if let dataChange = self.dataChange {
            let reload = dataChange.willReload(indexPair, state: .afterUpdate)
            
            if let indexPairBeforeUpdate = dataChange.indexPairBeforeUpdate(for: indexPair), !reload {
                return self.layoutModel(.beforeUpdate)!.layoutAttributes(forCellAt: indexPairBeforeUpdate)?.withIndexPair(indexPair)
            } else {
                let transition: ElementTransition = reload ? .reload : .insertion
                
                switch self.transitionAnimation(for: .cell(indexPair), transition: transition, state: .afterUpdate) {
                case .none:
                    return self.layoutModel(.afterUpdate)?.layoutAttributes(forCellAt: indexPair)
                case .opacity:
                    return self.layoutModel(.afterUpdate)?.layoutAttributes(forCellAt: indexPair)?.with(alpha: 0)
                    
                case .custom:
                    return self.layoutModel(.afterUpdate)?.initialLayoutAttributes(forInsertedItemAt: indexPair)
                }
            }
        }
        
        let attrs = self.layoutModel(.beforeUpdate)?.layoutAttributes(forCellAt: indexPair)
        return attrs
    }
    
    func layoutAttributes(forCellAt indexPair: IndexPair) -> LayoutAttributes? {
        let layoutAttrs = self.layoutModel(.afterUpdate)?.layoutAttributes(forCellAt: indexPair)
        return layoutAttrs
    }
    
    func layoutAttributes(forDisappearingItemAt indexPair: IndexPair) -> LayoutAttributes? {
        if let dataChange = self.dataChange {
            let reload = dataChange.willReload(indexPair, state: .beforeUpdate)
            
            if let indexPairAfterUpdate = dataChange.indexPairAfterUpdate(for: indexPair), !reload {
                return self.layoutModel(.afterUpdate)!.layoutAttributes(forCellAt: indexPairAfterUpdate)?.withIndexPair(indexPair)
            } else {
                let transition: ElementTransition = reload ? .reload : .deletion
                
                switch self.transitionAnimation(for: .cell(indexPair), transition: transition, state: .beforeUpdate) {
                case .none:
                    return self.layoutModel(.beforeUpdate)?.layoutAttributes(forCellAt: indexPair)
                    
                case .opacity:
                    return self.layoutModel(.beforeUpdate)?.layoutAttributes(forCellAt: indexPair)?.with(alpha: 0)
                    
                case .custom:
                    return self.layoutModel(.beforeUpdate)?.finalLayoutAttributes(forDeletedItemAt: indexPair)
                }
                
            }
        }
        
        let attrs = self.layoutModel(.afterUpdate)?.layoutAttributes(forCellAt: indexPair)
        return attrs
    }
    
    
    
    // MARK: Supplementary Views
    
    
    func layoutAttributes(forAppearingSupplementaryElement element: Element) -> LayoutAttributes? {
        assert(element.elementKind.isSupplementaryView)
        
        if let dataChange = self.dataChange {
            let reload = dataChange.willReload(element.indexPair, state: .afterUpdate)
            
            if let indexPairBeforeUpdate = dataChange.indexPairBeforeUpdate(for: element.indexPair), !reload {
                return self.stickyController(.beforeUpdate)?.layoutAttributes(for: Element(indexPair: indexPairBeforeUpdate, elementKind: element.elementKind))?.withIndexPair(element.indexPair)
                
            } else {
                let transition: ElementTransition = reload ? .reload : .insertion
                
                switch self.transitionAnimation(for: element, transition: transition, state: .afterUpdate) {
                    
                case .none:
                    return self.stickyController(.afterUpdate)?.layoutAttributes(for: element)
                case .opacity:
                    return self.stickyController(.afterUpdate)?.layoutAttributes(for: element)?.with(alpha: 0)
                    
                case .custom:
                    return self.layoutModel(.afterUpdate)?.initialLayoutAttributes(forAdditionalInsertedSupplementaryViewOfKind: element.elementKind.representedElementKind!, at: element.indexPair, isReloading: reload).flatMap {
                        self.stickyController(.afterUpdate)?.stickify($0)
                    }
                }
            }
        }
        
        return self.stickyController(.beforeUpdate)?.layoutAttributes(for: element)
    }
    
    func layoutAttributes(forSupplementaryElement element: Element) -> LayoutAttributes? {
        assert(element.elementKind.isSupplementaryView)
        
        return self.stickyController(.afterUpdate)?.layoutAttributes(for: element)
    }
    
    func layoutAttributes(forDisappearingSupplementaryElement element: Element) -> LayoutAttributes? {
        assert(element.elementKind.isSupplementaryView)
        
        if let dataChange = self.dataChange {
            let reload = dataChange.willReload(element.indexPair, state: .beforeUpdate)
            
            if let indexPairAfterUpdate = dataChange.indexPairAfterUpdate(for: element.indexPair), !reload {
                return self.stickyController(.afterUpdate)?.layoutAttributes(for: Element(indexPair: indexPairAfterUpdate,
                                                                                          elementKind: element.elementKind))?.withIndexPair(element.indexPair)
            } else {
                let transition: ElementTransition = reload ? .reload : .deletion
                
                switch self.transitionAnimation(for: element, transition: transition, state: .beforeUpdate)  {
                case .none:
                    var layoutAttrs = self.stickyController(.beforeUpdate)?.layoutAttributes(for: element)
                    
                    // For some reason, we need to change the zIndex of the layout attributes by any amount for it to be respected at all. It is not clear yet why.
                    layoutAttrs?.zIndex += 1
                    return layoutAttrs
                case .opacity:
                    var layoutAttrs = self.stickyController(.beforeUpdate)?.layoutAttributes(for: element)?.with(alpha: 0)
                    
                    // For some reason, we need to change the zIndex of the layout attributes by any amount for it to be respected at all. It is not clear yet why.
                    layoutAttrs?.zIndex += 1
                    return layoutAttrs
                    
                case .custom:
                    return self.layoutModel(.beforeUpdate)?.finalLayoutAttributes(forAdditionalDeletedSupplementaryViewOfKind: element.elementKind.representedElementKind!, at: element.indexPair, isReloading: reload).flatMap {
                        var attrs = self.stickyController(.beforeUpdate)?.stickify($0)
                        attrs?.zIndex += 1
                        return attrs
                    }
                }
            }
        }
        
        return self.stickyController(.afterUpdate)?.layoutAttributes(for: element)
    }
}
