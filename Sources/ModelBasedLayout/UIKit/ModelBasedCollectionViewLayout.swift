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
    
    public var debuggingRecorder: DebuggingRecorder?
    
    
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
        let result = self.controller.collectionViewContentSize
        self.debuggingRecorder?.record(.collectionViewContentSize(result: result))
        return result
    }
    
    // MARK: Prepare
    public override func prepare() {
        self.debuggingRecorder?.record(.prepare)
        super.prepare()
        self.controller.prepareIfNeeded()
    }
    
    // MARK: Prepare: Animated Bounds Change
    public override func prepare(forAnimatedBoundsChange oldBounds: CGRect) {
        self.debuggingRecorder?.record(.prepareForAnimatedBoundsChange(oldBound: oldBounds))
        super.prepare(forAnimatedBoundsChange: oldBounds)
        self.controller.prepareIfNeeded()
    }
    
    public override func finalizeAnimatedBoundsChange() {
        self.debuggingRecorder?.record(.finalizeAnimatedBoundsChange)
        super.finalizeAnimatedBoundsChange()
        self.controller.finalize()
    }

    // MARK: Prepare: Collection View Updates
    public override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        self.debuggingRecorder?.record(.prepareForCollectionViewUpdates(updateItems: updateItems.map { .init(from: $0) }))
        super.prepare(forCollectionViewUpdates: updateItems)
        self.controller.prepare(forCollectionViewUpdates: updateItems)
    }
    
    public override func finalizeCollectionViewUpdates() {
        self.debuggingRecorder?.record(.finalizeCollectionViewUpdates)
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
        self.debuggingRecorder?.record(.invalidateModel)
        let context = InvalidationContext()
        context.invalidateModel = true
        self.invalidateLayout(with: context)
    }
    
    public override func invalidateLayout() {
        self.debuggingRecorder?.record(.invalidateLayout)
        super.invalidateLayout()
    }
    
    public override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        self.debuggingRecorder?.record(.invalidateLayoutWith(context: .init(from: context as! InvalidationContext)))
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
        self.debuggingRecorder?.record(.invalidationContextForBoundsChange(newBounds: newBounds, result: .init(from: context as! InvalidationContext)))
        return context
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let result = self.controller.shouldInvalidateLayout(forBoundsChange: newBounds)
        self.debuggingRecorder?.record(.shouldInvalidateLayoutForBoundsChange(newBounds: newBounds, result: result))
        return result
    }
    
    // MARK: Self Sizing Cells
    
    public override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        let result = self.controller.shouldInvalidateLayout(forSelfSizingElement: .init(preferredAttributes),
                                                      preferredSize: preferredAttributes.size)
        self.debuggingRecorder?.record(.shouldInvalidateLayoutForPreferredLayoutAttributes(preferredAttributes: .init(preferredAttributes),
                                                                                           originalAttributes: .init(originalAttributes),
                                                                                           result: result))
        return result
    }
    
    public override func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
        
        (context as! InvalidationContext).userCreatedContext = false
        
        self.controller.configureInvalidationContext(context: context as! InvalidationContext,
                                                     forSelfSizingElement: Element(preferredAttributes),
                                                     preferredSize: preferredAttributes.size)
        self.debuggingRecorder?.record(.invalidationContextForPreferredLayoutAttributes(preferredAttributes: .init(preferredAttributes), originalAttributes: .init(originalAttributes), result: .init(from: (context as! InvalidationContext))))
        return context
    }
    
    // MARK: Target Content Offset
    public override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        let result = self.controller.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        self.debuggingRecorder?.record(.targetContentOffsetForProposedContentOffset(proposedContentOffset: proposedContentOffset, velocity: nil, result: result))
        return result
    }
    
    public override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        let result = self.controller.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        self.debuggingRecorder?.record(.targetContentOffsetForProposedContentOffset(proposedContentOffset: proposedContentOffset, velocity: velocity, result: result))
        return result
    }
    
    // MARK: Attrs in Rect
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let result = self.controller.layoutAttributesForElements(in: rect)
        self.debuggingRecorder?.record(.layoutAttributesForElements(rect: rect, result: result))
        return result?.map {$0.forLayout()}
    }
    
    // MARK: Items
    public override func initialLayoutAttributesForAppearingItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.count == 2 else { return nil }
        let result = self.controller.layoutAttributes(forAppearingItemAt: .init(indexPath))
        self.debuggingRecorder?.record(.initialLayoutAttributesForAppearingItem(indexPath: .init(indexPath), result: result))
        return result?.forLayout()
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.count == 2 else { return nil }
        let result = self.controller.layoutAttributes(forCellAt: .init(indexPath))
        self.debuggingRecorder?.record(.layoutAttributesForItem(indexPath: .init(indexPath), result: result))
        return result?.forLayout()
    }

    public override func finalLayoutAttributesForDisappearingItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.count == 2 else { return nil }
        let result = self.controller.layoutAttributes(forDisappearingItemAt: .init(indexPath))
        self.debuggingRecorder?.record(.finalLayoutAttributesForDisappearingItem(indexPath: .init(indexPath), result: result))
        return result?.forLayout()
    }
    
    // MARK: Supplementary Views
    public override func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.count == 2 else { return nil }
        let element = Element(indexPair: .init(indexPath), elementKind: .init(supplementaryOfKind: elementKind))
        let result = self.controller.layoutAttributes(forAppearingSupplementaryElement: element)
        self.debuggingRecorder?.record(.initialLayoutAttributesForAppearingSupplementaryElement(elementKind: elementKind, indexPath: .init(indexPath), result: result))
        return result?.forLayout()
    }
    
    public override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.count == 2 else { return nil }
        let element = Element(indexPair: .init(indexPath), elementKind: .init(supplementaryOfKind: elementKind))
        let result = self.controller.layoutAttributes(forSupplementaryElement: element)
        self.debuggingRecorder?.record(.layoutAttributesForSupplementaryView(elementKind: elementKind, indexPath: .init(indexPath), result: result))
        return result?.forLayout()
    }
    
    public override func finalLayoutAttributesForDisappearingSupplementaryElement(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.count == 2 else { return nil }
        let element = Element(indexPair: .init(indexPath), elementKind: .init(supplementaryOfKind: elementKind))
        let result = self.controller.layoutAttributes(forDisappearingSupplementaryElement: element)
        self.debuggingRecorder?.record(.finalLayoutAttributesForDisappearingSupplementaryElement(elementKind: elementKind, indexPath: .init(indexPath), result: result))
        return result?.forLayout()
    }
}


