//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import UIKit


class LayoutController<ModelType: LayoutModel> {
    enum UpdateState {
        case beforeUpdate, afterUpdate
    }
    
    private var prepareActions: PrepareActions = []
    private var dataChange: DataBatchUpdate? = nil
    
    private var stickyControllers: [String: StickyController] = [:]
    private var lastInvalidatedBounds: CGRect? = nil
    
    // MARK: Layout Model & Data
    struct Layout {
        let geometryInfo: GeometryInfo
        let dataSourceCounts: DataSourceCounts
        let stickyController: StickyController
        var model: ModelType
    }
    
    private var layoutAfterUpdate: Layout?
    private var layoutBeforeUpdate: Layout?
    
    private(set) var modelProvider: (_ dataSourceCounts: DataSourceCounts, _ geometryInfo: GeometryInfo) -> ModelType
    private(set) var dataSourceCountsProvider: () -> DataSourceCounts
    private(set) var geometryInfoProvider: () -> GeometryInfo
    private(set) var boundsProvider: () -> CGRect
    
    init(_ model: @escaping (_ dataSourceCounts: DataSourceCounts, _ geometryInfo: GeometryInfo) -> ModelType,
         dataSourceCounts: @escaping () -> DataSourceCounts,
         geometryInfo: @escaping () -> GeometryInfo,
         boundsProvider: @escaping () -> CGRect) {
        self.modelProvider = model
        self.dataSourceCountsProvider = dataSourceCounts
        self.geometryInfoProvider = geometryInfo
        self.boundsProvider = boundsProvider
    }
    
    func layoutModel(_ state: UpdateState) -> ModelType? {
        switch state {
        case .beforeUpdate:
            return layoutBeforeUpdate?.model
        case .afterUpdate:
            return layoutAfterUpdate?.model
        }
    }
    
    func dataSourceCounts(_ state: UpdateState) -> DataSourceCounts? {
        switch state {
        case .beforeUpdate:
            return layoutBeforeUpdate?.dataSourceCounts
        case .afterUpdate:
            return layoutAfterUpdate?.dataSourceCounts
        }
    }
    
    func geometryInfo(_ state: UpdateState) -> GeometryInfo? {
        switch state {
        case .beforeUpdate:
            return layoutBeforeUpdate?.geometryInfo
        case .afterUpdate:
            return layoutAfterUpdate?.geometryInfo
        }
    }
    
    func makeNewLayout(dataSourceCounts: DataSourceCounts? = nil, geometryInfo: GeometryInfo? = nil) -> Layout {
        let dataSourceCounts = dataSourceCounts ?? dataSourceCountsProvider()
        let geometryInfo = geometryInfo ?? geometryInfoProvider()
        
        let model = modelProvider(dataSourceCounts, geometryInfo)
        let stickyController = StickyController(stickyEdges: model.pinSectionHeadersToEdges,
                                                dataSourceCounts: dataSourceCounts,
                                                geometryInfo: geometryInfo,
                                                boundsProvider: self.boundsProvider) { section in
            model.layoutAttributes(forHeaderOfSection: section)
        }
        
        return Layout(geometryInfo: geometryInfo, dataSourceCounts: dataSourceCounts, stickyController: stickyController, model: model)
    }
    
    func needsToReplaceModel() {
        self.prepareActions.insert(.replaceModel)
    }
    
//    private func stickyController(for elementKind: String) -> StickyController {
//        if let stickyController = self.stickyControllers[elementKind] {
//            return stickyController
//        }
//
//        self.stickyControllers[elementKind] = StickyController()
//
//        return self.stickyControllers[elementKind]!
//    }
    
    // MARK: Prepare
    func prepare() {
        if self.layoutModel(.afterUpdate) == nil {
            self.layoutAfterUpdate = self.makeNewLayout()
        } else if prepareActions.contains(.replaceModel) {
            self.layoutBeforeUpdate = self.layoutAfterUpdate
            self.layoutAfterUpdate = self.makeNewLayout()
        }
        
        self.layoutAfterUpdate?.stickyController.unfreezeLayoutAttributes()
        
        self.prepareActions = []
    }
    
    func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        self.dataChange = DataBatchUpdate(dataSourceCounts: self.dataSourceCounts(.beforeUpdate)!, updateItems: updateItems)
    }
    
    func finalize() {
        self.layoutBeforeUpdate = nil
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
        (self.layoutAfterUpdate?.stickyController.stickyEdges ?? .none) != .none
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
    
    func configureInvalidationContext(forBoundsChange newBounds: CGRect, with context: UICollectionViewLayoutInvalidationContext, contentOffset: CGPoint) {
        if let geometryBefore = self.geometryInfo(.afterUpdate),
           newBounds.size != geometryBefore.viewSize,
           let currentModel = self.layoutModel(.afterUpdate),
            context.contentOffsetAdjustment == .zero {
            // viewSize change
            
            var geometryAfter = geometryInfoProvider()
            geometryAfter.viewSize = newBounds.size
            
            let newLayout = self.makeNewLayout(geometryInfo: geometryAfter)
            
            context.contentSizeAdjustment = newLayout.model.contentSize - currentModel.contentSize
            context.contentOffsetAdjustment = self.getContentOffsetAdjustment(contentSizeBefore: currentModel.contentSize,
                                                                              geometryBefore: geometryBefore,
                                                                              contentSizeAfter: newLayout.model.contentSize,
                                                                              geometryAfter: geometryAfter,
                                                                              contentOffset: contentOffset).cgPoint
            
            
            self.layoutAfterUpdate?.stickyController.freezeLayoutAttributes()
        }
        
        if self.usesStickyViews(), let stickyController = self.layoutAfterUpdate?.stickyController {
            let rect = boundsProvider().union(newBounds)
            let invalidation = stickyController.indexPathsToInvalidate(in: rect)
            context.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader, at: invalidation)
        }
    }
    
    func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        if context.invalidateDataSourceCounts || context.invalidateEverything || context.contentSizeAdjustment != .zero  || context.contentOffsetAdjustment != .zero  {
            self.needsToReplaceModel()
        }
        
        self.layoutAfterUpdate?.stickyController.invalidateVisibleBounds()
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
        let headers = self.layoutAfterUpdate!.stickyController.layoutAttributes(in: rect, visibleSections: visibleSections)
//        let headers = (firstVisibleSection...lastVisibleSection)
//            .compactMap { self.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: $0))}
//            .filter { $0.frame.intersects(rect) }
        results.append(contentsOf: headers)
        
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
    
    private func layoutAttributes(forSupplementaryViewOfKind elementKind: String, at indexPath: IndexPath, state: UpdateState) -> LayoutAttributes? {
        let layout = state == .afterUpdate ? layoutAfterUpdate : layoutBeforeUpdate
        
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            return layout?.stickyController.layoutAttributes(for: indexPath.section)
        default:
            return layout?.model.layoutAttributes(forSupplementaryViewAt: indexPath, with: elementKind)
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
        
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            let attrs = self.layoutBeforeUpdate?.stickyController.layoutAttributes(for: indexPath.section)
            return attrs
        default:
            return self.layoutAttributes(forSupplementaryViewOfKind: elementKind, at: indexPath, state: .beforeUpdate)
        }
        

    }
    
    func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> LayoutAttributes? {
        var attrs = self.layoutAttributes(forSupplementaryViewOfKind: elementKind, at: indexPath, state: .afterUpdate)
        //attrs?.transform = .init(scaleX: 10, y: 1)
        return attrs
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
        
        var attrs = self.layoutAttributes(forSupplementaryViewOfKind: elementKind, at: indexPath, state: .afterUpdate)
        //attrs?.transform = .init(scaleX: 10, y: 1)
        return attrs
    }
}
