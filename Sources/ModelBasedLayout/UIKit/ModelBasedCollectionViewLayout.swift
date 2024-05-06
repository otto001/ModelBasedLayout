//
//  ModelBasedCollectionViewLayout.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 15.07.23.
//

import UIKit



// MARK: ModelBasedCollectionViewLayout
open class ModelBasedCollectionViewLayout<ModelType: LayoutModel>: UICollectionViewLayout {
    public class override var invalidationContextClass: AnyClass { InvalidationContext.self }
    
    private var controller: LayoutController<ModelType>!
    
    private(set) var transitioningFrom: UICollectionViewLayout?
    private(set) var transitioningTo: UICollectionViewLayout?
    private(set) var transitionLayout: UICollectionViewTransitionLayout?
    
    
    var isTransitioning: Bool {
        return self.transitioningFrom != nil || self.transitioningTo != nil
    }
    
    public var layoutModel: ModelType? {
        self.controller.layoutModel(.afterUpdate)
    }
    
    public init(_ model: @escaping (_ dataSourceCounts: DataSourceCounts, _ geometryInfo: GeometryInfo) -> ModelType) {

        super.init()
        self.controller = .init(model) {
            DataSourceCounts(collectionView: self.collectionView!)
        } geometryInfo: {
            GeometryInfo(collectionView: self.collectionView!)
        } boundsInfoProvider: { [weak self] in
            guard let collectionView = self?.collectionView else {
                return .init(bounds: .zero, safeAreaInsets: .zero, adjustedContentInset: .zero)
            }
            return .init(bounds: collectionView.bounds,
                         safeAreaInsets: collectionView.safeAreaInsets,
                         adjustedContentInset: collectionView.adjustedContentInset)
        }
    }
    

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: ContentSize
    public override var collectionViewContentSize: CGSize {
        self.controller.collectionViewContentSize
    }
    
    // MARK: Prepare
    public override func prepare() {
        super.prepare()
        self.controller.prepareIfNeeded()
    }
    
    // MARK: Prepare: Animated Bounds Change
    public override func prepare(forAnimatedBoundsChange oldBounds: CGRect) {
        super.prepare(forAnimatedBoundsChange: oldBounds)
        self.controller.prepareIfNeeded()
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
    public func invalidateModel() {
        let context = InvalidationContext()
        context.invalidateModel = true
        self.invalidateLayout(with: context)
    }
    
    public override func invalidateLayout() {
        super.invalidateLayout()
    }
    
    public override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        super.invalidateLayout(with: context)
        
        if self.collectionView != nil {
            self.controller.invalidateLayout(with: context as! InvalidationContext)
        }
    }
    
    public override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        
        (context as! InvalidationContext).userCreatedContext = false
        
        if self.collectionView != nil {
            self.controller.configureInvalidationContext(context: context as! InvalidationContext, forBoundsChange: newBounds)
        }
        
        return context
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return self.controller.shouldInvalidateLayout(forBoundsChange: newBounds)
    }
    
    // MARK: Self Sizing Cells
    
    public override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        return self.controller.shouldInvalidateLayout(forSelfSizingElement: .init(preferredAttributes),
                                                      preferredSize: preferredAttributes.size)
    }
    
    public override func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
        
        (context as! InvalidationContext).userCreatedContext = false
        
        self.controller.configureInvalidationContext(context: context as! InvalidationContext,
                                                     forSelfSizingElement: Element(preferredAttributes),
                                                     preferredSize: preferredAttributes.size)
        return context
    }
    
    // MARK: Target Content Offset
    public override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        self.controller.targetContentOffset(forProposedContentOffset: proposedContentOffset)
    }
    
    public override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        self.controller.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
    }
    
    // MARK: Attrs in Rect
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        self.controller.layoutAttributesForElements(in: rect)?.map {$0.forLayout()}
    }
    
    // MARK: Items
    public override func initialLayoutAttributesForAppearingItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.count == 2 else { return nil }
        return self.controller.layoutAttributes(forAppearingItemAt: .init(indexPath))?.forLayout()
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.count == 2 else { return nil }
        return self.controller.layoutAttributes(forCellAt: .init(indexPath))?.forLayout()
    }

    public override func finalLayoutAttributesForDisappearingItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.count == 2 else { return nil }
        return self.controller.layoutAttributes(forDisappearingItemAt: .init(indexPath))?.forLayout()
    }
    
    // MARK: Supplementary Views
    public override func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.count == 2 else { return nil }
        let element = Element(indexPair: .init(indexPath), elementKind: .init(supplementaryOfKind: elementKind))
        return self.controller.layoutAttributes(forAppearingSupplementaryElement: element)?.forLayout()
    }
    
    public override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.count == 2 else { return nil }
        let element = Element(indexPair: .init(indexPath), elementKind: .init(supplementaryOfKind: elementKind))
        return self.controller.layoutAttributes(forSupplementaryElement: element)?.forLayout()
    }
    
    public override func finalLayoutAttributesForDisappearingSupplementaryElement(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.count == 2 else { return nil }
        let element = Element(indexPair: .init(indexPath), elementKind: .init(supplementaryOfKind: elementKind))
        return self.controller.layoutAttributes(forDisappearingSupplementaryElement: element)?.forLayout()
    }
}


