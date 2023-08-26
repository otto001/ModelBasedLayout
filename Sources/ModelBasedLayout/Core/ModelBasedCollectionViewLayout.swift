//
//  ModelBasedCollectionViewLayout.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 15.07.23.
//

import UIKit



// MARK: ModelBasedCollectionViewLayout
public class ModelBasedCollectionViewLayout<ModelType: LayoutModel>: UICollectionViewLayout {

    
    private var controller: LayoutController<ModelType>!
    
    private(set) var transitioningFrom: UICollectionViewLayout?
    private(set) var transitioningTo: UICollectionViewLayout?
    private(set) var transitionLayout: UICollectionViewTransitionLayout?
    
    var isTransitioning: Bool {
        return self.transitioningFrom != nil || self.transitioningTo != nil
    }
    
    public init(_ model: @escaping (_ dataSourceCounts: DataSourceCounts, _ geometryInfo: GeometryInfo) -> ModelType) {

        super.init()
        self.controller = .init(model) {
            DataSourceCounts(collectionView: self.collectionView!)
        } geometryInfo: {
            GeometryInfo(collectionView: self.collectionView!)
        }
    }
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: ContentSize
    public override var collectionViewContentSize: CGSize {
        if let model = self.controller.layoutModel(.afterUpdate) {
            return model.contentSize
        }
        return .zero
    }
    
    // MARK: Prepare
    public override func prepare() {
        self.controller.prepare()
        
        super.prepare()
        
    }
    
    // MARK: Prepare: Animated Bounds Change
    public override func prepare(forAnimatedBoundsChange oldBounds: CGRect) {
        super.prepare(forAnimatedBoundsChange: oldBounds)
    }
    
    public override func finalizeAnimatedBoundsChange() {
        super.finalizeAnimatedBoundsChange()
        self.controller.finalize()
    }

    // MARK: Prepare: Collection View Updates
    public override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        self.controller.prepare(forCollectionViewUpdates: updateItems)
    }
    
    public override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()
        self.controller.finalize()
    }
    
    // MARK: Prepare: Transitions
//    public override func prepareForTransition(from oldLayout: UICollectionViewLayout) {
//        if let transitionLayout = oldLayout as? UICollectionViewTransitionLayout {
//            self.transitionLayout = transitionLayout
//            self.transitioningFrom = transitionLayout.currentLayout
//        } else {
//            self.transitioningFrom = oldLayout
//        }
//
//        super.prepareForTransition(from: oldLayout)
//    }
//
//    public override func prepareForTransition(to newLayout: UICollectionViewLayout) {
//        if let transitionLayout = newLayout as? UICollectionViewTransitionLayout {
//            self.transitionLayout = transitionLayout
//            self.transitioningTo = transitionLayout.nextLayout
//        } else {
//            self.transitioningTo = newLayout
//        }
//
//        super.prepareForTransition(to: newLayout)
//    }
//
//    public override func finalizeLayoutTransition() {
//        self.transitioningFrom = nil
//        self.transitioningTo = nil
//        super.finalizeLayoutTransition()
//    }

    // MARK: Invalidation
    public override func invalidateLayout() {
        super.invalidateLayout()
    }
    
 
    public override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        super.invalidateLayout(with: context)
        
        if let collectionView = self.collectionView {
            self.controller.invalidateForSizeChange(newBounds: collectionView.bounds, with: context, for: collectionView)
        }
        
        if context.invalidateDataSourceCounts || context.invalidateEverything || context.contentSizeAdjustment != .zero  || context.contentOffsetAdjustment != .zero  {
            self.controller.needsToReplaceModel()
        }
    }
    
    public override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        
        if let collectionView = self.collectionView {
            self.controller.invalidateForSizeChange(newBounds: newBounds, with: context, for: collectionView)
        }
        
        return context
    }
    

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if newBounds.size != self.controller.geometryInfo(.afterUpdate)?.viewSize {
            return true
        }
        return super.shouldInvalidateLayout(forBoundsChange: newBounds)
    }
    
    // MARK: Attrs in Rect
    
    public override final func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // TODO: Optimize!
        self.controller.layoutAttributesForElements(in: rect)?.map {$0.forLayout()}
    }
    
    // MARK: Items

    public override final func initialLayoutAttributesForAppearingItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        self.controller.initialLayoutAttributesForAppearingItem(at: indexPath)?.forLayout()
    }

    public override final func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        self.controller.layoutAttributesForItem(at: indexPath)?.forLayout()
    }

    public override final func finalLayoutAttributesForDisappearingItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        self.controller.finalLayoutAttributesForDisappearingItem(at: indexPath)?.forLayout()
    }
    
    
    
    // MARK: Supplementary Views
    public override final func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        self.controller.initialLayoutAttributesForAppearingSupplementaryElement(ofKind: elementKind, at: indexPath)?.forLayout()
    }
    
    public override final func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        self.controller.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)?.forLayout()
    }
    
    public override final func finalLayoutAttributesForDisappearingSupplementaryElement(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        self.controller.finalLayoutAttributesForDisappearingSupplementaryElement(ofKind: elementKind, at: indexPath)?.forLayout()
    }
}


