//
//  File.swift
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
    
    // MARK: Rect
    func layoutAttributesForElements(in rect: CGRect) -> [LayoutAttributes]? {
        let items = self.layoutModel(.afterUpdate)!.items(in: rect)
        return items.compactMap { (item: Item) -> LayoutAttributes? in
            switch item {
            case .cell(let indexPair):
                return self.layoutAttributesForItem(at: indexPair)
            case .header(let section):
                return self.stickyController(.afterUpdate)?.layoutAttributes(forItemOfKind: .header, at: IndexPair(item: 0, section: section))
            case .footer(let section):
                return self.stickyController(.afterUpdate)?.layoutAttributes(forItemOfKind: .footer, at: IndexPair(item: 0, section: section))
                
            case .additionalSupplementaryView(let elementKind, let indexPair):
                return self.stickyController(.afterUpdate)?.layoutAttributes(forItemOfKind: .additionalSupplementaryView(elementKind), at: indexPair)

            }
        }
        
    }
    
    // MARK: Layout Attributes
    func initialLayoutAttributesForAppearingItem(at indexPair: IndexPair) -> LayoutAttributes? {
        
        if let dataChange = self.dataChange {
            if let indexPairBeforeUpdate = dataChange.indexPairBeforeUpdate(for: indexPair) {
                return self.layoutModel(.beforeUpdate)!.layoutAttributes(forItemAt: indexPairBeforeUpdate)?.withIndexPair(indexPair)
            } else {
                switch (self.layoutModel(.afterUpdate)?.transitionAnimation(for: .cell(indexPair)) ?? .none) {
                case .none:
                    return self.layoutModel(.afterUpdate)?.layoutAttributes(forItemAt: indexPair)
                case .opacity:
                    var layoutAttrs = self.layoutModel(.afterUpdate)?.layoutAttributes(forItemAt: indexPair)
                    layoutAttrs?.alpha = 0
                    return layoutAttrs
                    
                case .custom:
                    return self.layoutModel(.afterUpdate)?.initialLayoutAttributes(forInsertedItemAt: indexPair)
                }
            }
        }
        
        let attrs = self.layoutModel(.beforeUpdate)?.layoutAttributes(forItemAt: indexPair)
        return attrs
    }
    
    func layoutAttributesForItem(at indexPair: IndexPair) -> LayoutAttributes? {
        let layoutAttrs = self.layoutModel(.afterUpdate)?.layoutAttributes(forItemAt: indexPair)
        return layoutAttrs
    }
    
    func finalLayoutAttributesForDisappearingItem(at indexPair: IndexPair) -> LayoutAttributes? {
        if let dataChange = self.dataChange {
            if dataChange.indexPairAfterUpdate(for: indexPair) != nil {
                return nil
            } else {
                switch (self.layoutModel(.beforeUpdate)?.transitionAnimation(for: .cell(indexPair)) ?? .none) {
                case .none:
                    return self.layoutModel(.beforeUpdate)?.layoutAttributes(forItemAt: indexPair)
                    
                case .opacity:
                    var layoutAttrs = self.layoutModel(.beforeUpdate)?.layoutAttributes(forItemAt: indexPair)
                    layoutAttrs?.alpha = 0
                    return layoutAttrs
                    
                case .custom:
                    return self.layoutModel(.beforeUpdate)?.finalLayoutAttributes(forDeletedItemAt: indexPair)
                }
                
            }
        }
        
        let attrs = self.layoutModel(.afterUpdate)?.layoutAttributes(forItemAt: indexPair)
        return attrs
    }
    
    
    
    // MARK: Supplementary Views
    
    func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at indexPair: IndexPair) -> LayoutAttributes? {
        
        if let dataChange = self.dataChange {
            if let indexPairBeforeUpdate = dataChange.indexPairBeforeUpdate(for: indexPair) {
                return self.stickyController(.beforeUpdate)?.layoutAttributes(forItemOfKind: .init(supplementaryOfKind: elementKind), at: indexPairBeforeUpdate)?.withIndexPair(indexPair)
                
            } else {
                switch (self.layoutModel(.afterUpdate)?.transitionAnimation(for: .init(supplementaryOfKind: elementKind, indexPair: indexPair)) ?? .none) {
                case .none:
                    return self.stickyController(.afterUpdate)?.layoutAttributes(forItemOfKind: .init(supplementaryOfKind: elementKind), at: indexPair)
                case .opacity:
                    var layoutAttrs = self.stickyController(.afterUpdate)?.layoutAttributes(forItemOfKind: .init(supplementaryOfKind: elementKind), at: indexPair)
                    layoutAttrs?.alpha = 0
                    return layoutAttrs
                    
                case .custom:
                    return self.layoutModel(.afterUpdate)?.initialLayoutAttributes(forAdditionalInsertedSupplementaryViewOfKind: elementKind, at: indexPair)
                }
            }
        }
        
        return self.stickyController(.beforeUpdate)?.layoutAttributes(forItemOfKind: .init(supplementaryOfKind: elementKind), at: indexPair)
    }
    
    func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPair: IndexPair) -> LayoutAttributes? {
        self.stickyController(.afterUpdate)?.layoutAttributes(forItemOfKind: .init(supplementaryOfKind: elementKind), at: indexPair)
    }
    
    func finalLayoutAttributesForDisappearingSupplementaryElement(ofKind elementKind: String, at indexPair: IndexPair) -> LayoutAttributes? {
        
        if let dataChange = self.dataChange {
            if dataChange.indexPairAfterUpdate(for: indexPair) != nil {
                return nil
            } else {
                switch (self.layoutModel(.beforeUpdate)?.transitionAnimation(for: .init(supplementaryOfKind: elementKind, indexPair: indexPair)) ?? .none)  {
                case .none:
                    var layoutAttrs = self.stickyController(.beforeUpdate)?.layoutAttributes(forItemOfKind: .init(supplementaryOfKind: elementKind), at: indexPair)
                    layoutAttrs?.zIndex += 1
                    return layoutAttrs
                case .opacity:
                    var layoutAttrs = self.stickyController(.beforeUpdate)?.layoutAttributes(forItemOfKind: .init(supplementaryOfKind: elementKind), at: indexPair)
                    layoutAttrs?.alpha = 0
                    
                    // For some reason, we need to change the zIndex of the layout attributes by any amount for it to be respected at all. It is not clear yet why.
                    layoutAttrs?.zIndex += 1
                    return layoutAttrs
                    
                case .custom:
                    return self.layoutModel(.beforeUpdate)?.finalLayoutAttributes(forAdditionalDeletedSupplementaryViewOfKind: elementKind, at: indexPair)
                }
            }
        }
        
        return self.stickyController(.afterUpdate)?.layoutAttributes(forItemOfKind: .init(supplementaryOfKind: elementKind), at: indexPair)
    }
}
