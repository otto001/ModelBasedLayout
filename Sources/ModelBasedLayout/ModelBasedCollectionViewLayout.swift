//
//  ModelBasedCollectionViewLayout.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 15.07.23.
//

import UIKit

// Layout transition order of operation (especially important for for working with sticky headers)
//
// prepare new layout (called twice for some reason)
// old layout returns old attrs (called from setCollectionViewLayout)
// new layout returns new (but not necessarily final) attrs (called from setCollectionViewLayout)
//
// old layout returns new, final attrs in final layout call (called from setCollectionViewLayout / doubleSidedAnimation)
//      uses: new layout returns new, final attrs
//
// new layout returns old attrs in initial layout call (called from setCollectionViewLayout / doubleSidedAnimation)
//      uses: old layout returns old attrs in layout call
//
// new layout returns new, final attrs in layout call (after animation completes)
//
// Result:
//  Animation A: old layout -> old final
//  Animation B: new inital -> new layout

// Issue: Animation A & B are not identical
// Solution 1: Hide Animation B by setting isHidden = true
// Solution 2: Hide Animation B by setting isHidden = true (does not work properly for some reason)


// MARK: ModelBasedCollectionViewLayoutInvalidationContext
class ModelBasedCollectionViewLayoutInvalidationContext: UICollectionViewLayoutInvalidationContext {
    //var invalidateModelBasedLayoutData: Bool = false
}


// MARK: ModelBasedCollectionViewLayout
public class ModelBasedCollectionViewLayout<ModelType: LayoutModel>: UICollectionViewLayout {
    public override class var invalidationContextClass: AnyClass { ModelBasedCollectionViewLayoutInvalidationContext.self }
    
    enum TransitionAnimation {
        case opacity, custom
    }
    
    var transitionAnimation: TransitionAnimation = .opacity
    
    enum UpdateState {
        case beforeUpdate, afterUpdate
    }
    
    private var prepareActions: PrepareActions = []
    private var dataChange: DataBatchUpdate? = nil
    
    struct Layout {
        let data: ModelBasedLayoutData
        var model: ModelType
    }
    
    private var layoutAfterUpdate: Layout?
    private var layoutBeforeUpdate: Layout?
    
    var layoutModel: ModelType? {
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
    
    func layoutData(_ state: UpdateState) -> ModelBasedLayoutData? {
        switch state {
        case .beforeUpdate:
            return layoutBeforeUpdate?.data
        case .afterUpdate:
            return layoutAfterUpdate?.data
        }
    }
    
    private(set) var transitioningFrom: UICollectionViewLayout?
    private(set) var transitioningTo: UICollectionViewLayout?
    private(set) var transitionLayout: UICollectionViewTransitionLayout?
    
    var isTransitioning: Bool {
        return self.transitioningFrom != nil || self.transitioningTo != nil
    }
    

    
    private(set) var modelClosure: (_ layoutData: ModelBasedLayoutData) -> ModelType
    
    public init(_ model: @escaping (_ layoutData: ModelBasedLayoutData) -> ModelType) {
        self.modelClosure = model
        super.init()
    }
    
    private func makeNewLayout(overrideCollectionViewSize: CGSize? = nil) -> Layout {
        let layoutData = ModelBasedLayoutData(collectionView: self.collectionView!, overrideCollectionViewSize: overrideCollectionViewSize)
        return Layout(data: layoutData, model: modelClosure(layoutData))
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
//        if collectionView?.bounds.size != self.layoutData?.collectionViewSize {
//            self.needsModelBasedLayoutDataUpdate = true
//        }
        
        super.prepare(forAnimatedBoundsChange: oldBounds)
    }
    
    public override func finalizeAnimatedBoundsChange() {
        super.finalizeAnimatedBoundsChange()
        self.layoutBeforeUpdate = nil
    }

    // MARK: Prepare: Collection View Updates
    public override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        
        dataChange = DataBatchUpdate(layoutData: self.layoutData(.beforeUpdate)!, updateItems: updateItems)
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
    
    private func getContentOffsetAdjustment(contentSizeBefore: CGSize, boundsBefore: CGRect,
                                            contentSizeAfter: CGSize, boundsAfer: CGRect) -> CGSize {
        guard contentSizeBefore > .zero && contentSizeAfter > .zero  else { return .zero }

        let currentContentOffset = self.collectionView!.contentOffset.cgSize


        let oldHalfBoundsSize = (boundsBefore.size/2)
        let halfBoundsSize = (boundsAfer.size/2)

        let scrollRatio = (currentContentOffset + oldHalfBoundsSize) / contentSizeBefore


        return (scrollRatio * contentSizeAfter - halfBoundsSize) - currentContentOffset //.clamp(min: self.contentOffsetMin, max: self.contentOffsetMax)
    }
    
    // MARK: Invalidation
    public override func invalidateLayout() {
        super.invalidateLayout()
    }
    
    public override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        super.invalidateLayout(with: context)
        
        if context.invalidateDataSourceCounts || context.invalidateEverything {
            self.prepareActions.insert(.replaceModel)
        }
    }
    
    public override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        
        if newBounds.size != self.layoutData(.afterUpdate)?.collectionViewSize {
            let newModel = self.makeNewLayout(overrideCollectionViewSize: newBounds.size)
            let contentSizeAdjustment = newModel.model.contentSize - self.layoutModel!.contentSize
            context.contentSizeAdjustment = contentSizeAdjustment
            context.contentOffsetAdjustment = self.getContentOffsetAdjustment(contentSizeBefore: self.layoutModel!.contentSize, boundsBefore: self.collectionView!.bounds, contentSizeAfter: newModel.model.contentSize, boundsAfer: newBounds).cgPoint
            self.prepareActions.insert(.replaceModel)
            //(context as? ModelBasedCollectionViewLayoutInvalidationContext)?.invalidateModelBasedLayoutData = true
        }

        return context
    }
    

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if newBounds.size != self.layoutData(.afterUpdate)?.collectionViewSize {
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
                case .opacity:
                    var layoutAttrs = self.layoutModel(.afterUpdate)!.layoutAttributes(forItemAt: indexPath)
                    layoutAttrs?.alpha = 0
                    return layoutAttrs?.forLayout()
                    
                case .custom:
                    return self.layoutModel(.afterUpdate)!.initialLayoutAttributes(forInsertedItemAt: indexPath)?.forLayout()
                }
            }
        }

        let attrs = self.layoutModel(.beforeUpdate)!.layoutAttributes(forItemAt: indexPath)
        return attrs?.forLayout()
    }

    public override final func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let layoutAttrs = self.layoutModel(.afterUpdate)!.layoutAttributes(forItemAt: indexPath)
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
                case .opacity:
                    var layoutAttrs = self.layoutModel(.beforeUpdate)!.layoutAttributes(forItemAt: indexPath)
                    layoutAttrs?.alpha = 0
                    return layoutAttrs?.forLayout()
                    
                case .custom:
                    return self.layoutModel(.beforeUpdate)!.finalLayoutAttributes(forDeletedItemAt: indexPath)?.forLayout()
                }
                
            }
        }

        let attrs = self.layoutModel(.afterUpdate)!.layoutAttributes(forItemAt: indexPath)
        return attrs?.forLayout()
    }
}

private struct PrepareActions: OptionSet {
    let rawValue: UInt
    
    static let replaceModel = PrepareActions(rawValue: 1 << 0)
}


