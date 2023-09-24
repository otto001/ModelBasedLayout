//
//  LayoutController.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import UIKit


class LayoutController<ModelType: LayoutModel> {
    
    private let stateController: LayoutStateController<ModelType>
    
    private var dataChange: DataBatchUpdate? = nil
    
    private var targetContentOffset: CGPoint? = nil
    private var targetContentOffsetAdjustment: CGPoint = .zero
    
    private(set) var boundsInfoProvider: () -> BoundsInfo
    
    init(_ model: @escaping (_ dataSourceCounts: DataSourceCounts, _ geometryInfo: GeometryInfo) -> ModelType,
         dataSourceCounts: @escaping () -> DataSourceCounts,
         geometryInfo: @escaping () -> GeometryInfo,
         boundsInfoProvider: @escaping () -> BoundsInfo) {
        
        self.stateController = .init(modelProvider: model, dataSourceCountsProvider: dataSourceCounts, geometryInfoProvider: geometryInfo, boundsInfoProvider: boundsInfoProvider)
        
        self.boundsInfoProvider = boundsInfoProvider
    }
    
    // MARK: Accessors
    internal func layoutModel(_ state: LayoutState) -> ModelType? {
        self.stateController.layout(state)?.model
    }
    
    private func dataSourceCounts(_ state: LayoutState) -> DataSourceCounts? {
        self.stateController.layout(state)?.dataSourceCounts
    }
    
    private func geometryInfo(_ state: LayoutState) -> GeometryInfo? {
        self.stateController.layout(state)?.geometryInfo
    }
    
    private func stickyController(_ state: LayoutState) -> StickyController? {
        self.stateController.layout(state)?.stickyController
    }
    
    private func boundsController(_ state: LayoutState) -> BoundsController? {
        self.stateController.layout(state)?.boundsController
    }
    
    // MARK: Content Size
    var collectionViewContentSize: CGSize {
        if let model = self.layoutModel(.afterUpdate) {
            return model.contentSize
        }
        return .zero
    }
    
    // MARK: Prepare & Finalize
    func prepare() {
        if self.layoutModel(.afterUpdate) == nil {
            self.stateController.pushNewLayout()
        }
        self.boundsController(.afterUpdate)?.updateBoundsIfNeeded()
        
        self.targetContentOffsetAdjustment = .zero
    }
    
    func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        guard !updateItems.isEmpty else { return }
        self.dataChange = DataBatchUpdate(dataSourceCounts: self.dataSourceCounts(.beforeUpdate)!, updateItems: updateItems)
        
        self.prepareTargetContentOffset()
        
        if let targetContentOffset = self.targetContentOffset {
            self.boundsController(.afterUpdate)?.setTargetContentOffset(target: targetContentOffset)
        }
    }
    
    func finalize() {
        self.stateController.clearLayoutBefore()
        self.dataChange = nil
        self.targetContentOffsetAdjustment = .zero
        self.targetContentOffset = nil
    }
    
    private func usesStickyViews() -> Bool {
        self.stickyController(.afterUpdate)?.usesStickyViews ?? false
    }
    
    // MARK: Content Offset Adjustment
    private func prepareTargetContentOffset() {
        guard let before = self.stateController.layout(.beforeUpdate),
              let after = self.stateController.layout(.afterUpdate),
              let result = self.targetContentOffset(from: before, to: after) else {
            return
            
        }
        self.targetContentOffset = result
    }
    
    func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if targetContentOffset == nil {
            self.prepareTargetContentOffset()
        }
        
        guard let targetContentOffset = self.targetContentOffset else {
            return proposedContentOffset
        }
        
        self.targetContentOffsetAdjustment = proposedContentOffset - targetContentOffset
        return targetContentOffset
    }
    
    private func targetContentOffset(from originContainer: LayoutContainer<ModelType>, to targetContainer: LayoutContainer<ModelType>) -> CGPoint? {
        let oldBounds = originContainer.boundsController.boundsInfo
        let newBoundsInfo = self.boundsInfoProvider()
        
        guard oldBounds.bounds.size > .zero && newBoundsInfo.bounds.size > .zero else { return nil }
        
        guard var contentOffsetAnchor = originContainer.model.contentOffsetAnchor(in: oldBounds) else { return nil }
        
        if let dataChange = dataChange {
            if let updatedIndexPair = dataChange.indexPairAfterUpdate(for: contentOffsetAnchor.element.indexPair) {
                contentOffsetAnchor.element.indexPair = updatedIndexPair
            } else {
                return nil
            }
        }
        
        guard let newContentOffset = self.layoutModel(.afterUpdate)?.contentOffset(for: contentOffsetAnchor, proposedBounds: newBoundsInfo, currentBounds: oldBounds) else { return nil }
        

        let contentSize = targetContainer.model.contentSize
        let targetInsets = newBoundsInfo.adjustedContentInset

        let minContentOffset = CGPoint(x: -targetInsets.left,
                                       y: -targetInsets.top)
        let maxContentOffset = CGPoint(x: contentSize.width + targetInsets.right - newBoundsInfo.bounds.width,
                                       y: contentSize.height + targetInsets.bottom - newBoundsInfo.bounds.height)
        
        let result = CGPoint(x: max(minContentOffset.x, min(maxContentOffset.x, newContentOffset.x)),
                             y: max(minContentOffset.y, min(maxContentOffset.y, newContentOffset.y)))
        
        return result
    }
    
    private func contentOffsetAdjustmentFalback(from originContainer: LayoutContainer<ModelType>, to targetContainer: LayoutContainer<ModelType>) -> CGSize {
        let contentSizeBefore = originContainer.model.contentSize
        let contentSizeAfter = targetContainer.model.contentSize
        
        guard contentSizeBefore > .zero else { return .zero }
        
        let boundsInfoBefore = originContainer.boundsController.boundsInfo
        let boundsInfoAfter = targetContainer.boundsController.boundsInfo
        
        let currentContentOffset = boundsInfoAfter.bounds.origin.cgSize
        
        let halfBoundsSizeBefore = (originContainer.geometryInfo.viewSize/2)
        let halfBoundsSizeAfter = (targetContainer.geometryInfo.viewSize/2)
        
        let insetBefore = CGSize(width: boundsInfoBefore.adjustedContentInset.left, height: boundsInfoBefore.adjustedContentInset.top)
        let insetAfter = CGSize(width: boundsInfoAfter.adjustedContentInset.left, height: boundsInfoAfter.adjustedContentInset.top)
        let insetDiff = insetBefore - insetAfter
        
        let scrollRatio = (currentContentOffset + halfBoundsSizeBefore - insetDiff) / contentSizeBefore
        
        return (scrollRatio * contentSizeAfter - halfBoundsSizeAfter) - currentContentOffset
    }
    
    func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        var proposal = self.boundsInfoProvider()
        proposal.bounds.origin = proposedContentOffset
        
        return self.layoutModel(.afterUpdate)?.contentOffset(proposedBounds: proposal, scrollingVelocity: velocity) ?? proposedContentOffset
    }
   
    // MARK: Invalidation
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        
        if let boundsController = self.boundsController(.afterUpdate) {
            boundsController.freeze()
            defer { boundsController.unfreeze() }
            guard boundsController.bounds != newBounds else { return false }
        }
        
        if newBounds.size != self.geometryInfo(.afterUpdate)?.viewSize {
            return true
        }
        
        if self.stickyController(.afterUpdate)?.shouldInvalidateLayout(forBoundsChange: newBounds) == true {
            return true
        }
        
        if var newBoundsInfo = self.boundsController(.afterUpdate)?.boundsInfo, newBoundsInfo.bounds != newBounds {
            newBoundsInfo.bounds = newBounds
            
            if !self.layoutModel(.afterUpdate)!.elements(affectedByBoundsChange: newBoundsInfo, in: newBounds).isEmpty {
                return true
            }
        }
        
        return false
    }
    
    func configureInvalidationContext(context: InvalidationContext, forBoundsChange newBounds: CGRect) {
        let boundsController = self.boundsController(.afterUpdate)
        assert(boundsController?.frozen != true)
        boundsController?.freeze()
        
        if let geometryBefore = self.geometryInfo(.afterUpdate),
           newBounds.size != geometryBefore.viewSize,
           let currentLayout = self.stateController.layout(.afterUpdate),
           !context.invalidateGeometryInfo {
            // viewSize change
            
            context.invalidateGeometryInfo = true
            
            let newLayout = self.stateController.makeNewLayout(forNewBounds: newBounds)
            context.contentSizeAdjustment = newLayout.model.contentSize - currentLayout.model.contentSize
            
            if let target = self.targetContentOffset(from: currentLayout, to: newLayout) {
                context.contentOffsetAdjustment = (target - boundsInfoProvider().bounds.origin)
            } else {
                context.contentOffsetAdjustment = self.contentOffsetAdjustmentFalback(from: currentLayout, to: newLayout).cgPoint
            }
        }
        
        if self.usesStickyViews(), let stickyController = self.stickyController(.afterUpdate) {
            stickyController.configureInvalidationContext(forBoundsChange: newBounds, with: context)
        }
        
        if var newBoundsInfo = self.boundsController(.afterUpdate)?.boundsInfo {
            newBoundsInfo.bounds = newBounds
            
            let elementsToInvalidate = self.layoutModel(.afterUpdate)!.elements(affectedByBoundsChange: newBoundsInfo, in: newBounds)
            for element in elementsToInvalidate {
                context.invalidateElement(element)
            }
        }
        
        boundsController?.unfreeze()
    }
    
    func invalidateLayout(with context: InvalidationContext) {
        if context.invalidateStickyCache {
            self.stickyController(.afterUpdate)?.resetCache()
        }
        
        if context.invalidateDataSourceCounts || context.invalidateEverything || context.invalidateModel || context.invalidateGeometryInfo  {
            self.stateController.pushNewLayout()
            self.boundsController(.beforeUpdate)?.freeze()
            self.stickyController(.beforeUpdate)?.willBeReplaced()
        }
        
        self.boundsController(.afterUpdate)?.invalidate()
    }
    
    // MARK: Self Sizing
    func shouldInvalidateLayout(forSelfSizingElement element: Element, preferredSize: CGSize) -> Bool {
        guard let attrsBefore = self.layoutAttributes(for: element) else { return false }
        self.layoutModel(.afterUpdate)?.adjustForSelfSizing(element: element, preferredSize: preferredSize)
        let attrsAfter = self.layoutAttributes(for: element)
        
        return attrsBefore.frame.size != attrsAfter?.frame.size
    }
    
    func configureInvalidationContext(context: InvalidationContext, forSelfSizingElement element: Element, preferredSize: CGSize) {
        context.invalidateElement(element)
        context.invalidateStickyCache = true
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
                return self.layoutModel(.beforeUpdate)!.layoutAttributes(for: .cell(indexPairBeforeUpdate))?.withIndexPair(indexPair)
            } else {
                let transition: ElementTransition = reload ? .reload : .insertion
                
                switch self.transitionAnimation(for: .cell(indexPair), transition: transition, state: .afterUpdate) {
                case .none:
                    return self.layoutModel(.afterUpdate)?.layoutAttributes(for: .cell(indexPair))?.offset(by: self.targetContentOffsetAdjustment)
                case .opacity:
                    return self.layoutModel(.afterUpdate)?.layoutAttributes(for: .cell(indexPair))?.with(alpha: 0).offset(by: self.targetContentOffsetAdjustment)
                case .custom:
                    return self.layoutModel(.afterUpdate)?.layoutAttributes(for: .cell(indexPair), frame: .initial(reload: reload))?.offset(by: self.targetContentOffsetAdjustment)
                }
            }
        }
        
        guard self.dataSourceCounts(.beforeUpdate)?.contains(indexPair: indexPair) == true else { return nil }
        return self.layoutModel(.beforeUpdate)?.layoutAttributes(for: .cell(indexPair))
    }
    
    func layoutAttributes(forCellAt indexPair: IndexPair) -> LayoutAttributes? {
        let layoutAttrs = self.layoutModel(.afterUpdate)?.layoutAttributes(for: .cell(indexPair))
        return layoutAttrs
    }
    
    func layoutAttributes(forDisappearingItemAt indexPair: IndexPair) -> LayoutAttributes? {
        if let dataChange = self.dataChange {
            let reload = dataChange.willReload(indexPair, state: .beforeUpdate)
            
            if let indexPairAfterUpdate = dataChange.indexPairAfterUpdate(for: indexPair), !reload {
                return self.layoutModel(.afterUpdate)!.layoutAttributes(for: .cell(indexPairAfterUpdate))?.withIndexPair(indexPair)
            } else {
                let transition: ElementTransition = reload ? .reload : .deletion
                
                switch self.transitionAnimation(for: .cell(indexPair), transition: transition, state: .beforeUpdate) {
                case .none:
                    return self.layoutModel(.beforeUpdate)?.layoutAttributes(for: .cell(indexPair))
                    
                case .opacity:
                    return self.layoutModel(.beforeUpdate)?.layoutAttributes(for: .cell(indexPair))?.with(alpha: 0)
                    
                case .custom:
                    return self.layoutModel(.beforeUpdate)?.layoutAttributes(for: .cell(indexPair), frame: .final(reload: reload))
                }
                
            }
        }
        
        let attrs = self.layoutModel(.afterUpdate)?.layoutAttributes(for: .cell(indexPair))
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
                    return self.stickyController(.afterUpdate)?.layoutAttributes(for: element)?.offset(by: self.targetContentOffsetAdjustment)
                case .opacity:
                    return self.stickyController(.afterUpdate)?.layoutAttributes(for: element)?.with(alpha: 0).offset(by: self.targetContentOffsetAdjustment)
                    
                case .custom:
                    return self.layoutModel(.afterUpdate)?.layoutAttributes(for: element, frame: .initial(reload: reload)).flatMap {
                        self.stickyController(.afterUpdate)?.stickify($0)
                    }?.offset(by: self.targetContentOffsetAdjustment)
                }
            }
        }
        
        guard self.dataSourceCounts(.beforeUpdate)?.contains(indexPair: element.indexPair) == true else { return nil }
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
                    return self.layoutModel(.beforeUpdate)?.layoutAttributes(for: element, frame: .final(reload: reload)).flatMap {
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
