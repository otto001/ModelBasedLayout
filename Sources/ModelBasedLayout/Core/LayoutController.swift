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
    
    private func layoutModel(_ state: LayoutState) -> ModelType? {
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
        
        assert(self.stickyController(.afterUpdate)?.frozen != true)
        //self.stickyController(.afterUpdate)?.unfreezeLayoutAttributes()
        
        self.prepareActions = []
    }
    
    func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
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
        (self.stickyController(.afterUpdate)?.stickyEdges ?? .none) != .none
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
            let rect = boundsProvider().union(newBounds)
            let invalidation = stickyController.indexPathsToInvalidate(in: rect)
            context.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader, at: invalidation)
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
        // TODO: Optimize!
        guard let dataSourceCounts = self.dataSourceCounts(.afterUpdate) else { return nil }
        
        let indexPaths = (0..<dataSourceCounts.itemsCount).lazy.map { dataSourceCounts.indexPath(for: $0) }
        
        let cells = indexPaths.map { self.layoutAttributesForItem(at: $0) }

        let cellRange = cells.binarySearchRange { attrs in
            if attrs!.frame.intersects(rect) {
                return .equal
            } else if attrs!.frame.maxY <= rect.minY || attrs!.frame.maxX <= rect.minX {
                return .before
            } else {
                return .after
            }
        }

        guard let cellRange = cellRange else {
            return nil
        }

        var results = Array(cells[cellRange].compactMap {$0})
        
        
        let firstVisibleSection = cells[cellRange.lowerBound]!.indexPath.section
        let lastVisibleSection = cells[cellRange.upperBound]!.indexPath.section
        let visibleSections = (firstVisibleSection...lastVisibleSection).map { $0 }
        if let headers = self.stickyController(.afterUpdate)?.layoutAttributes(in: rect, visibleSections: visibleSections) {
            results.append(contentsOf: headers)
        }
        
       return results
    }
    
    // MARK: Layout Attributes
    func initialLayoutAttributesForAppearingItem(at indexPath: IndexPath) -> LayoutAttributes? {

        if let dataChange = self.dataChange {
            if let indexPathBeforeUpdate = dataChange.indexPathBeforeUpdate(for: indexPath) {
                return self.layoutModel(.beforeUpdate)!.layoutAttributes(forItemAt: indexPathBeforeUpdate)
            } else {
                switch (self.layoutModel(.afterUpdate)?.transitionAnimation(forItemAt: indexPath) ?? .none) {
                case .none:
                    return self.layoutModel(.afterUpdate)?.layoutAttributes(forItemAt: indexPath)
                case .opacity:
                    var layoutAttrs = self.layoutModel(.afterUpdate)?.layoutAttributes(forItemAt: indexPath)
                    layoutAttrs?.alpha = 0
                    return layoutAttrs
                    
                case .custom:
                    return self.layoutModel(.afterUpdate)?.initialLayoutAttributes(forInsertedItemAt: indexPath)
                }
            }
        }
        
        let attrs = self.layoutModel(.beforeUpdate)?.layoutAttributes(forItemAt: indexPath)
        return attrs
    }
    
    func layoutAttributesForItem(at indexPath: IndexPath) -> LayoutAttributes? {
        let layoutAttrs = self.layoutModel(.afterUpdate)?.layoutAttributes(forItemAt: indexPath)
        return layoutAttrs
    }
    
    func finalLayoutAttributesForDisappearingItem(at indexPath: IndexPath) -> LayoutAttributes? {
        if let dataChange = self.dataChange {
            if dataChange.indexPathAfterUpdate(for: indexPath) != nil {
                return nil
            } else {
                switch (self.layoutModel(.beforeUpdate)?.transitionAnimation(forItemAt: indexPath) ?? .none) {
                case .none:
                    return self.layoutModel(.beforeUpdate)?.layoutAttributes(forItemAt: indexPath)
                    
                case .opacity:
                    var layoutAttrs = self.layoutModel(.beforeUpdate)?.layoutAttributes(forItemAt: indexPath)
                    layoutAttrs?.alpha = 0
                    return layoutAttrs
                    
                case .custom:
                    return self.layoutModel(.beforeUpdate)?.finalLayoutAttributes(forDeletedItemAt: indexPath)
                }
                
            }
        }
        
        let attrs = self.layoutModel(.afterUpdate)?.layoutAttributes(forItemAt: indexPath)
        return attrs
    }
    
    
    
    // MARK: Supplementary Views
    
    private func layoutAttributes(forSupplementaryViewOfKind elementKind: String,
                                  at indexPath: IndexPath,
                                  state: LayoutState) -> LayoutAttributes? {
        let layout = self.container.layout(state)
        
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            return layout?.stickyController.layoutAttributes(for: indexPath.section)
        default:
            return layout?.model.layoutAttributes(forAdditionalSupplementaryViewOfKind: elementKind, at: indexPath)
        }
        
    }
    
    func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at indexPath: IndexPath) -> LayoutAttributes? {
        // TODO: Data Change
        
//        if let dataChange = self.dataChange {
//            if let indexPathBeforeUpdate = dataChange.indexPathBeforeUpdate(for: indexPath) {
//                return self.layoutModel(.beforeUpdate)!.layoutAttributes(forSupplementaryViewAt: indexPathBeforeUpdate, with: elementKind)
//            } else {
//                switch (self.layoutModel(.afterUpdate)?.transitionAnimation(forSupplementaryViewAt: indexPath, with: elementKind) ?? .none) {
//                case .none:
//                    return self.layoutModel(.afterUpdate)?.layoutAttributes(forSupplementaryViewAt: indexPath, with: elementKind)
//                case .opacity:
//                    var layoutAttrs = self.layoutModel(.afterUpdate)?.layoutAttributes(forSupplementaryViewAt: indexPath, with: elementKind)
//                    layoutAttrs?.alpha = 0
//                    return layoutAttrs
//
//                case .custom:
//                    return self.layoutModel(.afterUpdate)?.initialLayoutAttributes(forInsertedSupplementaryViewAt: indexPath, with: elementKind)
//                }
//            }
//        }
        
        return self.layoutAttributes(forSupplementaryViewOfKind: elementKind, at: indexPath, state: .beforeUpdate)
    }
    
    func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> LayoutAttributes? {
        return self.layoutAttributes(forSupplementaryViewOfKind: elementKind, at: indexPath, state: .afterUpdate)
    }
    
    func finalLayoutAttributesForDisappearingSupplementaryElement(ofKind elementKind: String, at indexPath: IndexPath) -> LayoutAttributes? {
        // TODO: Data Change
        
//        if let dataChange = self.dataChange {
//            if dataChange.indexPathAfterUpdate(for: indexPath) != nil {
//                return nil
//            } else {
//                switch (self.layoutModel(.beforeUpdate)?.transitionAnimation(forSupplementaryViewAt: indexPath, with: elementKind) ?? .none)  {
//                case .none:
//                    return self.layoutModel(.beforeUpdate)?.layoutAttributes(forSupplementaryViewAt: indexPath, with: elementKind)
//                case .opacity:
//                    var layoutAttrs = self.layoutModel(.beforeUpdate)?.layoutAttributes(forSupplementaryViewAt: indexPath, with: elementKind)
//                    layoutAttrs?.alpha = 0
//                    return layoutAttrs
//
//                case .custom:
//                    return self.layoutModel(.beforeUpdate)?.finalLayoutAttributes(forDeletedSupplementaryViewAt: indexPath, with: elementKind)
//                }
//            }
//        }
        
        return self.layoutAttributes(forSupplementaryViewOfKind: elementKind, at: indexPath, state: .afterUpdate)
    }
}
