//
//  StickyController.swift
//  
//
//  Created by Matteo Ludwig on 26.08.23.
//

import UIKit

/// A controller that manages the sticky behaviour of elements in a collection view.
class StickyController {
    
    /// The bounds controller that provides the bounds of the collection view.
    private var boundsController: BoundsController

    /// A closure that provides the layout attributes for an element.
    private var layoutAttributesProvider: (_ element: Element) -> LayoutAttributes?
    
    /// A cache that stores the layout attributes for elements. The cache is used to avoid recalculating the layout attributes for elements that have already been calculated.
    private var cachedAttributes: [Element: LayoutAttributes] = [:]

    /// A map that stores the elements that are sticky and their sticky bounds. This map is used to determine which elements need to be invalidated when the bounds of the collection view change.
    private var invalidationMap: ChunkedRectMap<Element>
    
    /// The bounds that were last invalidated. Used to prevent multiple invalidations for the same bounds.
    private var lastInvalidatedBounds: CGRect = .zero
    
    // TODO: Determine if this property is necessary. It is currently only used for the fade bounding behaviour.
    private var isBeingTransitionOut: Bool = false
    
    /// A boolean value that determines if the layout uses sticky views. It is set to true once the controller encounters a sticky element. Once set to true, it will remain true.
    private(set) var usesStickyViews: Bool = false
    
    /// Initializes the sticky controller with the specified bounds controller and layout attributes provider.
    /// - Parameters: boundsController: The bounds controller that provides the bounds of the collection view.
    /// - Parameters: layoutAttributesProvider: A closure that provides the layout attributes for an element.
    init(boundsController: BoundsController,
         layoutAttributesProvider: @escaping (_ element: Element) -> LayoutAttributes?) {
        
        self.boundsController = boundsController
        self.layoutAttributesProvider = layoutAttributesProvider
        
        var chunkSize = boundsController.bounds.size
        if chunkSize == .zero {
            chunkSize = CGSize(width: 1_000, height: 1_000)
        }
        self.invalidationMap = .init(chunkSize: chunkSize)
    }
    
    func willBeReplaced() {
        self.isBeingTransitionOut = true
    }
    
    /// A boolean value that determines if the layout should be invalidated for the specified bounds change.
    /// - Parameter newBounds: The new bounds of the collection view.
    /// - Returns: True if the layout should be invalidated for the specified bounds change, false otherwise.
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if self.usesStickyViews && self.lastInvalidatedBounds != newBounds {
            self.lastInvalidatedBounds = newBounds
            return true
        }
        return false
    }
    
    /// Returns the bounds the element should stick to for the specified sticky attributes.
    /// - Parameter stickyAttributes: The sticky attributes to get the bounds for.
    /// - Returns: The bounds the element should stick to for the specified sticky attributes. These bounds will be the bounds returned by the bounds controller, inset by the additional insets of the sticky attributes and the safe area insets if specified.
    private func bounds(for stickyAttributes: StickyAttributes) -> CGRect {
        (stickyAttributes.useSafeAreaInsets ? self.boundsController.safeAreaBounds : self.boundsController.bounds).inset(by: stickyAttributes.additionalInsets)
    }
    
    /// Returns the layout attributes for the specified element. If the element is sticky, the controller will insert the element into the invalidation map and set the `usesStickyViews` property to `true`. All layout attributes are cached, regardless of whether they are sticky or not.
    /// - Parameter element: The element to get the layout attributes for.
    /// - Returns: The layout attributes for the specified element.
    private func baseLayoutAttributes(for element: Element) -> LayoutAttributes? {
        // Return cached attributes if available
        if let attrs = self.cachedAttributes[element] {
            return attrs
        }
        
        let attrs = layoutAttributesProvider(element)
        if let attrs = attrs {
            self.cachedAttributes[element] = attrs
            
            if attrs.isSticky {
                // If the element is sticky, insert it into the invalidation map and set the usesStickyViews property to true.
                // As the invalidation map is later used to determine which elements need to be invalidated when the bounds of the collection view change, we use the extended sticky bounds of the element when inserting it into the map.
                self.invalidationMap.insert(element, with: attrs.extendedStickyBounds!)
                self.usesStickyViews = true
            }
        }
        return attrs
    }
    
    /// Returns the layout attributes for the specified element, with sticky behaviour applied. This is done by changing the frame of the layout attributes to ensure that the element sticks to the edges of the collection view. Additional effects like fading or disappearing can be applied to the element when it reaches the sticky edges.
    /// - Parameter attrs: The layout attributes to apply sticky behaviour to.
    /// - Returns: The layout attributes with sticky behaviour applied.
    func stickify(_ attrs: LayoutAttributes) -> LayoutAttributes {
        // If the element is not sticky or has no size, return the attributes as is.
        guard let stickyAttrs = attrs.stickyAttributes, attrs.frame.width > 0, attrs.frame.height > 0 else { return attrs }
        
        var newAttrs = attrs
        
        // Ensure that the frame of the element is within the visible bounds of the collection view, adjusted by any additional insets and safe area insets.
        newAttrs.frame.ensureWithin(self.bounds(for: stickyAttrs), edges: stickyAttrs.stickyEdges)
        
        // Check for misconfiguration of sticky attributes
        assert(stickyAttrs.stickyBounds.width >= newAttrs.frame.width && stickyAttrs.stickyBounds.height >= newAttrs.frame.height,
               "The frame of a LayoutAttributes struct must be smaller or equal in size to it's stickyBounds.")
        
        // Apply the sticky behaviour to the element based on the bounding behaviour.
        switch stickyAttrs.boundingBehaviour {
        case .push:
            // For push, the element will stick to the edges as long as it remains fully within the sticky bounds. Then, the element will be pushed out of the visible bounds to remain within the sticky bounds.
            newAttrs.frame.ensureWithin(stickyAttrs.stickyBounds, edges: .all)
        case .fade:
            // For fade, the element will fade out using opacity when it reaches the sticky edges. For this, the element will be allowed to move out of the sticky bounds by the size of its own frame. Once the frame and sticky bounds no longer intersect, the element will be fully hidden.
            let intersection = newAttrs.frame.intersection(stickyAttrs.stickyBounds)
            if !self.isBeingTransitionOut {
                // Setting the alpha based on the percentage of the intersection area to the frame area.
                newAttrs.alpha *= (intersection.width * intersection.height)/(newAttrs.frame.width * newAttrs.frame.height)
            }
            // Ensure that the frame is within the sticky bounds, but allow it to move out by the size of its own frame.
            newAttrs.frame.ensureWithin(stickyAttrs.stickyBounds.insetBy(dx: -newAttrs.frame.width, dy: -newAttrs.frame.height), edges: .all)
        case .disappear:
            // For disappear, the element will disappear when it reaches the sticky edges.
            newAttrs.isHidden = !newAttrs.frame.isWithin(stickyAttrs.stickyBounds, edges: .all)
        }
        
        return newAttrs
    }

    /// Returns the layout attributes for the specified element, with sticky behaviour applied.
    /// - Parameter element: The element to get the layout attributes for.
    /// - Returns: The layout attributes for the specified element, with sticky behaviour applied.
    func layoutAttributes(for element: Element) -> LayoutAttributes? {
        return self.baseLayoutAttributes(for: element).map {self.stickify($0)}
    }

    /// Configures the invalidation context for the specified bounds change. All elements that are sticky and may be affected by the bounds change are invalidated.
    /// - Parameters: newBounds: The new bounds of the collection view.
    /// - Parameters: context: The invalidation context to configure.
    func configureInvalidationContext(forBoundsChange newBounds: CGRect, with context: InvalidationContext) {
        // All elements within the old bounds and the new bounds may be affected by the bounds change. Therefore, we simply create the union of the old and new bounds.
        let rect = self.boundsController.bounds.union(newBounds)
        
        // Query the invalidation map for all elements that are within the specified rect. Then, only keep those which are not visible in the old bounds.
        let result = self.invalidationMap.query(rect).map {
            self.cachedAttributes[$0]!
        }.filter {
            return !$0.extendedStickyBounds!.isWithin(self.bounds(for: $0.stickyAttributes!), edges: $0.stickyAttributes!.stickyEdges)
        }
        
        // Invalidate the elements.
        for attrs in result {
            context.invalidateElement(attrs.element)
        }
    }
    
    // Invalidate caches of the controller based on the specified invalidation context.
    /// - Parameter context: The invalidation context to invalidate the caches with.
    func invalidate(with context: InvalidationContext) {
        if context.invalidateStickyCache {
            // If the sticky cache should be invalidated, clear the caches and the invalidation map.
            self.cachedAttributes.removeAll(keepingCapacity: true)
            self.invalidationMap.removeAll(keepingCapacity: true)
        } else {
            // If any dynamic elements should be invalidated, remove them from the caches and the invalidation map.
            if let invalidateDynamicElements = context.invalidateDynamicElements {
                for element in invalidateDynamicElements {
                    if self.cachedAttributes.removeValue(forKey: element) != nil {
                        self.invalidationMap.remove(value: element)
                    }
                }
            }
            
            // TODO: Document this
            if context.userCreatedContext, let invalidatedSupplementaryIndexPaths = context.invalidatedSupplementaryIndexPaths {
                for (elementKind, indexPaths) in invalidatedSupplementaryIndexPaths {
                    for indexPath in indexPaths {
                        let element: Element = .supplementaryView(ofKind: elementKind, at: IndexPair(indexPath))
                        if self.cachedAttributes.removeValue(forKey: element) != nil {
                            self.invalidationMap.remove(value: element)
                        }
                    }
                }
            }
        }
    }
}


private extension CGRect {
    /// Returns a new rect that is ensured to be within the specified rect on the specified edges.
    mutating func ensureWithin(_ other: CGRect, edges: Edges) {
        
        if edges.contains(.left) && self.minX < other.minX {
            self.origin.x = other.origin.x
        } else if edges.contains(.right) && self.maxX > other.maxX {
            self.origin.x = other.maxX - self.width
        }
        
        
        if edges.contains(.top) && self.minY < other.minY {
            self.origin.y = other.origin.y
        } else if edges.contains(.bottom) && self.maxY > other.maxY {
            self.origin.y = other.maxY - self.height
        }
    }
    
    /// Returns a boolean value that determines if the rect is within the specified rect on the specified edges.
    func isWithin(_ other: CGRect, edges: Edges) -> Bool {
        return !(edges.contains(.left) && self.minX < other.minX
        || edges.contains(.right) && self.maxX > other.maxX
        || edges.contains(.top) && self.minY < other.minY
        || edges.contains(.bottom) && self.maxY > other.maxY)
    }
}
