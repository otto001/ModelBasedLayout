//
//  ModelBasedCollectionViewLayout.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 15.07.23.
//

import UIKit



// MARK: ModelBasedCollectionViewLayout
public class ModelBasedCollectionViewLayout<ModelType: LayoutModel>: UICollectionViewLayout {

    public var transitionAnimation: TransitionAnimation = .opacity
    
    enum UpdateState {
        case beforeUpdate, afterUpdate
    }
    
    private var prepareActions: PrepareActions = []
    private var dataChange: DataBatchUpdate? = nil
    
    // MARK: Layout Model & Data
    struct Layout {
        let geometryInfo: GeometryInfo
        let dataSourceCounts: DataSourceCounts
        var model: ModelType
    }
    
    private var layoutAfterUpdate: Layout?
    private var layoutBeforeUpdate: Layout?
    
    public var layoutModel: ModelType? {
        layoutAfterUpdate?.model
    }
    
    private func layoutModel(_ state: UpdateState) -> ModelType? {
        switch state {
        case .beforeUpdate:
            return layoutBeforeUpdate?.model
        case .afterUpdate:
            return layoutAfterUpdate?.model
        }
    }
    
    private func dataSourceCounts(_ state: UpdateState) -> DataSourceCounts? {
        switch state {
        case .beforeUpdate:
            return layoutBeforeUpdate?.dataSourceCounts
        case .afterUpdate:
            return layoutAfterUpdate?.dataSourceCounts
        }
    }
    
    private func geometryInfo(_ state: UpdateState) -> GeometryInfo? {
        switch state {
        case .beforeUpdate:
            return layoutBeforeUpdate?.geometryInfo
        case .afterUpdate:
            return layoutAfterUpdate?.geometryInfo
        }
    }
    
    private(set) var transitioningFrom: UICollectionViewLayout?
    private(set) var transitioningTo: UICollectionViewLayout?
    private(set) var transitionLayout: UICollectionViewTransitionLayout?
    
    var isTransitioning: Bool {
        return self.transitioningFrom != nil || self.transitioningTo != nil
    }
    

    
    private(set) var modelClosure: (_ dataSourceCounts: DataSourceCounts, _ geometryInfo: GeometryInfo) -> ModelType
    
    public init(_ model: @escaping (_ dataSourceCounts: DataSourceCounts, _ geometryInfo: GeometryInfo) -> ModelType) {
        self.modelClosure = model
        super.init()
    }
    
    private func makeNewLayout(overrideCollectionViewSize: CGSize? = nil) -> Layout {
        let dataSourceCounts = DataSourceCounts(collectionView: self.collectionView!)
        let geometryInfo = GeometryInfo(viewSize: overrideCollectionViewSize ?? self.collectionView!.bounds.size,
                                        adjustedContentInset: self.collectionView!.adjustedContentInset,
                                        safeAreaInsets: self.collectionView!.safeAreaInsets)
        return Layout(geometryInfo: geometryInfo, dataSourceCounts: dataSourceCounts, model: modelClosure(dataSourceCounts, geometryInfo))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: ContentSize
    public override var collectionViewContentSize: CGSize {
        if let model = self.layoutModel(.afterUpdate) {
            return model.contentSize
        }
        return .zero
    }
    
    // MARK: Prepare
    public override func prepare() {
        if self.layoutModel(.afterUpdate) == nil {
            self.layoutAfterUpdate = self.makeNewLayout()
        } else if prepareActions.contains(.replaceModel) {
            self.layoutBeforeUpdate = self.layoutAfterUpdate
            self.layoutAfterUpdate = self.makeNewLayout()
        }
        
        
        super.prepare()
        
        self.prepareActions = []
    }
    
    // MARK: Prepare: Animated Bounds Change
    public override func prepare(forAnimatedBoundsChange oldBounds: CGRect) {
        super.prepare(forAnimatedBoundsChange: oldBounds)
    }
    
    public override func finalizeAnimatedBoundsChange() {
        super.finalizeAnimatedBoundsChange()
        self.layoutBeforeUpdate = nil
    }

    // MARK: Prepare: Collection View Updates
    public override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        
        dataChange = DataBatchUpdate(dataSourceCounts: self.dataSourceCounts(.beforeUpdate)!, updateItems: updateItems)
    }
    
    public override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()
        
        dataChange = nil
        
        self.layoutBeforeUpdate = nil
    }
    
    // MARK: Prepare: Transitions
    public override func prepareForTransition(from oldLayout: UICollectionViewLayout) {
        if let transitionLayout = oldLayout as? UICollectionViewTransitionLayout {
            self.transitionLayout = transitionLayout
            self.transitioningFrom = transitionLayout.currentLayout
        } else {
            self.transitioningFrom = oldLayout
        }
        
        super.prepareForTransition(from: oldLayout)
    }
    
    public override func prepareForTransition(to newLayout: UICollectionViewLayout) {
        if let transitionLayout = newLayout as? UICollectionViewTransitionLayout {
            self.transitionLayout = transitionLayout
            self.transitioningTo = transitionLayout.nextLayout
        } else {
            self.transitioningTo = newLayout
        }
        
        super.prepareForTransition(to: newLayout)
    }
    
    public override func finalizeLayoutTransition() {
        self.transitioningFrom = nil
        self.transitioningTo = nil
        super.finalizeLayoutTransition()
    }
    
    private func getContentOffsetAdjustment(contentSizeBefore: CGSize, geometryBefore: GeometryInfo,
                                            contentSizeAfter: CGSize, geometryAfter: GeometryInfo) -> CGSize {
        
        guard contentSizeBefore > .zero && contentSizeAfter > .zero  else { return .zero }

        let currentContentOffset = self.collectionView!.contentOffset.cgSize


        let halfBoundsSizeBefore = (geometryBefore.viewSize/2)
        let halfBoundsSizeAfter = (geometryAfter.viewSize/2)
        
        let insetBefore = CGSize(width: geometryBefore.adjustedContentInset.left, height: geometryBefore.adjustedContentInset.top)
        let insetAfter = CGSize(width: geometryAfter.adjustedContentInset.left, height: geometryAfter.adjustedContentInset.top)
        let insetDiff = insetBefore - insetAfter

        let scrollRatio = (currentContentOffset + halfBoundsSizeBefore - insetDiff) / contentSizeBefore
        
        return (scrollRatio * contentSizeAfter - halfBoundsSizeAfter) - currentContentOffset
    }
    
    // MARK: Invalidation
    public override func invalidateLayout() {
        super.invalidateLayout()
    }
    
    private func invalidateForSizeChange(newBounds: CGRect, with context: UICollectionViewLayoutInvalidationContext) {
        if let geometryBefore = self.geometryInfo(.afterUpdate),
           newBounds.size != geometryBefore.viewSize,
           let currentModel = self.layoutModel {
            
            let geometryAfter = GeometryInfo(viewSize: newBounds.size,
                                             adjustedContentInset: self.collectionView!.adjustedContentInset,
                                             safeAreaInsets: self.collectionView!.safeAreaInsets)
            
            let newModel = self.makeNewLayout(overrideCollectionViewSize: newBounds.size)
            let contentSizeAdjustment = newModel.model.contentSize - currentModel.contentSize
            
            context.contentSizeAdjustment = contentSizeAdjustment
            context.contentOffsetAdjustment = self.getContentOffsetAdjustment(contentSizeBefore: self.layoutModel!.contentSize,
                                                                              geometryBefore: geometryBefore,
                                                                              contentSizeAfter: newModel.model.contentSize,
                                                                              geometryAfter: geometryAfter).cgPoint
        }
    }
    
    public override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        super.invalidateLayout(with: context)
        
        if let collectionView = self.collectionView {
            self.invalidateForSizeChange(newBounds: collectionView.bounds, with: context)
        }
        
        if context.invalidateDataSourceCounts || context.invalidateEverything || context.contentSizeAdjustment != .zero  || context.contentOffsetAdjustment != .zero  {
            self.prepareActions.insert(.replaceModel)
        }
    }
    
    public override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        
        self.invalidateForSizeChange(newBounds: newBounds, with: context)

        return context
    }
    

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if newBounds.size != self.geometryInfo(.afterUpdate)?.viewSize {
            return true
        }
        return super.shouldInvalidateLayout(forBoundsChange: newBounds)
    }
    
    // MARK: Attrs in Rect
    
    public override final func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.layoutModel(.afterUpdate)!.layoutAttributes(in: rect).compactMap { $0.forLayout() }
    }
    
    // MARK: Items

    public override final func initialLayoutAttributesForAppearingItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        //print("Initial \(indexPath.section).\(indexPath.item)")
//        guard self.transitioningFrom == nil else {
//            return self.layoutAttributesForItem(at: indexPath)
//        }
        
        if let dataChange = dataChange {
            if let indexPathBeforeUpdate = dataChange.indexPathBeforeUpdate(for: indexPath) {
                return self.layoutModel(.beforeUpdate)!.layoutAttributes(forItemAt: indexPathBeforeUpdate)?.forLayout()
            } else {
                switch self.transitionAnimation {
                case .none:
                    return self.layoutModel(.afterUpdate)?.layoutAttributes(forItemAt: indexPath)?.forLayout()
                case .opacity:
                    var layoutAttrs = self.layoutModel(.afterUpdate)?.layoutAttributes(forItemAt: indexPath)
                    layoutAttrs?.alpha = 0
                    return layoutAttrs?.forLayout()
                    
                case .custom:
                    return self.layoutModel(.afterUpdate)?.initialLayoutAttributes(forInsertedItemAt: indexPath)?.forLayout()
                }
            }
        }

        let attrs = self.layoutModel(.beforeUpdate)?.layoutAttributes(forItemAt: indexPath)
        return attrs?.forLayout()
    }

    public override final func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let layoutAttrs = self.layoutModel(.afterUpdate)?.layoutAttributes(forItemAt: indexPath)
        //print("layout \(indexPath.section).\(indexPath.item) \(layoutAttrs!.center)")
        return layoutAttrs?.forLayout()
    }

    public override final func finalLayoutAttributesForDisappearingItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        //print("Final \(indexPath.section).\(indexPath.item)")
        
        if let dataChange = dataChange {
            if dataChange.indexPathAfterUpdate(for: indexPath) != nil {
                return nil
            } else {
                switch self.transitionAnimation {
                case .none:
                    return self.layoutModel(.beforeUpdate)?.layoutAttributes(forItemAt: indexPath)?.forLayout()
                    
                case .opacity:
                    var layoutAttrs = self.layoutModel(.beforeUpdate)?.layoutAttributes(forItemAt: indexPath)
                    layoutAttrs?.alpha = 0
                    return layoutAttrs?.forLayout()
                    
                case .custom:
                    return self.layoutModel(.beforeUpdate)?.finalLayoutAttributes(forDeletedItemAt: indexPath)?.forLayout()
                }
                
            }
        }

        let attrs = self.layoutModel(.afterUpdate)?.layoutAttributes(forItemAt: indexPath)
        return attrs?.forLayout()
    }
}


