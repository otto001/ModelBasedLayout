//
//  LayoutAttributes.swift
//  ModelBasedLayout
//
//  Created by Matteo Ludwig on 18.07.23.
//

import UIKit


/// The layout attributes of an element. Contains information about the element's geometry, visuals, and sticky attributes. This translates to `UICollectionViewLayoutAttributes` in UIKit.
public struct LayoutAttributes: Equatable, Codable {
    // MARK: Element
    // The element that the layout attributes belong to.
    public private(set) var element: Element

    /// A convenience property to access the index pair of the element.
    var indexPair: IndexPair { element.indexPair }

    /// A convenience property to access the element kind of the element.
    var elementKind: ElementKind { element.elementKind }
    
    
    // MARK: Geometry
    private var _frame: CGRect

    /// The transform of the element. The transform is applied to the frame.
    public var transform: CGAffineTransform
    
    /// The frame of the element. The frame is transformed by the `transform` property. When setting the frame, the transform is applied to the frame.
    public var frame: CGRect {
        get {
            return _frame.applying(transform)
        }
        set {
            _frame = newValue
        }
    }
    
    /// The bounds of the element. The bounds are equal to the frame's size and have an origin of (0, 0).
    public var bounds: CGRect {
        get {
            CGRect(origin: .zero, size: _frame.size)
        }
        set {
            assert(newValue.origin == .zero, "LayoutAttribute bounds must have their origin equal (0, 0).")
            _frame.size = newValue.size
        }
    }
    
    // MARK: Visuals
    /// The z-index of the element. The z-index determines the order of elements in the z-axis.
    public var zIndex: Int
    /// The alpha value of the element. The alpha value determines the opacity of the element.
    public var alpha: CGFloat
    /// A boolean value that determines if the element is hidden.
    public var isHidden: Bool
    
    
    // MARK: StickyAttributes
    /// The sticky attributes of the element. Sticky attributes define how the element behaves when it is scrolled out of view. If this property is nil, the element is not sticky.
    public var stickyAttributes: StickyAttributes?

    /// The extended sticky bounds of the element. The extended sticky bounds are the sticky bounds extended by the frame's size. This is used to determine if the element is visible when it is sticky. For non-sticky elements, this property is nil. For sticky elements with a `push` or `disappear` bounding behaviour, the extended sticky bounds are equal to the sticky bounds. For sticky elements with a `fade` bounding behaviour, the extended sticky bounds are the sticky bounds extended by the frame's size.
    internal var extendedStickyBounds: CGRect? {
        if let stickyAttributes = stickyAttributes {
            switch stickyAttributes.boundingBehaviour {
            case .push, .disappear:
                /// For push and disappear, the view will never be visible outside of the sticky bounds.
                return stickyAttributes.stickyBounds
            case .fade:
                /// For fade, the view will be visible outside of the sticky bounds by exactly the size of the view.
                return stickyAttributes.stickyBounds.insetBy(dx: -frame.width, dy: -frame.height)
            }
            
        }
        // Non-sticky elements do not have extended sticky bounds.
        return nil
    }
    
    /// A boolean value that determines if the element is sticky. True if the element has sticky attributes with at least one sticky edge.
    public var isSticky: Bool {
        guard let stickyAttributes = stickyAttributes else { return false }
        return stickyAttributes.stickyEdges != .none
    }
    
    // MARK: Init
    public init(element: Element,
                frame: CGRect = .zero, zIndex: Int = 0,
                alpha: CGFloat = 1, isHidden: Bool = false,
                transform: CGAffineTransform = .identity) {
        self.element = element
        self._frame = frame
        self.zIndex = zIndex
        self.alpha = alpha
        self.isHidden = isHidden
        self.transform = transform
    }
    
    // MARK: from UIKit
    /// Initializes the layout attributes from `UICollectionViewLayoutAttributes`.
    /// - Parameter collectionViewLayoutAttributes: The `UICollectionViewLayoutAttributes` to initialize from.
    /// - Note: Some properties are not supported by `LayoutAttributes` and are not copied. These properties include `transform3D`.
    public init(_ collectionViewLayoutAttributes: UICollectionViewLayoutAttributes) {
        self.element = .init(indexPair: .init(collectionViewLayoutAttributes.indexPath), elementKind: .init(from: collectionViewLayoutAttributes))
        
        
        self._frame = collectionViewLayoutAttributes.frame
        self.zIndex = collectionViewLayoutAttributes.zIndex
        
        self.alpha = collectionViewLayoutAttributes.alpha
        self.isHidden = collectionViewLayoutAttributes.isHidden
        
        self.transform = collectionViewLayoutAttributes.transform
        //self.transform3D = collectionViewLayoutAttributes.transform3D
    }
    
    // MARK: to UIKit
    /// Returns the layout attributes as `UICollectionViewLayoutAttributes`.
    /// - Returns: The layout attributes as `UICollectionViewLayoutAttributes`.
    /// - Note: Some properties are not supported by `LayoutAttributes` and are set to default values. These properties include `transform3D`.
    public func forLayout() -> UICollectionViewLayoutAttributes {
        let collectionViewLayoutAttributes: UICollectionViewLayoutAttributes
        
        
        switch self.element.elementKind {
        case .cell:
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forCellWith: element.indexPair.indexPath)
        case .header:
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: element.indexPair.indexPath)
        case .footer:
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: element.indexPair.indexPath)
        case .additionalSupplementaryView(let elementKind):
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: element.indexPair.indexPath)
        case .decorativeView(let elementKind):
            collectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: element.indexPair.indexPath)
        }
        
        collectionViewLayoutAttributes.frame = self._frame
        collectionViewLayoutAttributes.transform = self.transform
        
        
        collectionViewLayoutAttributes.alpha = self.alpha
        collectionViewLayoutAttributes.isHidden = self.isHidden
        collectionViewLayoutAttributes.zIndex = self.zIndex
        
        return collectionViewLayoutAttributes
    }
    
    // MARK: Helpers
    /// Returns a copy of the layout attributes with the given index pair.
    /// - Parameter indexPair: The index pair of the copy.
    /// - Returns: A copy of the layout attributes with the given index pair.
    internal func withIndexPair(_ indexPair: IndexPair) -> Self {
        var copy = self
        copy.element.indexPair = indexPair
        return copy
    }
    
    /// Returns a copy of the layout attributes with the given alpha value.
    /// - Parameter alpha: The alpha value of the copy.
    /// - Returns: A copy of the layout attributes with the given alpha value.
    public func with(alpha: CGFloat) -> Self {
        var copy = self
        copy.alpha = alpha
        return copy
    }
        
    /// Returns a copy of the layout attributes with the given offset applied to the frame.
    /// - Parameter point: The offset to apply to the frame of the copy.
    /// - Returns: A copy of the layout attributes with the given offset applied to the frame.
    public func offset(by point: CGPoint) -> Self {
        var copy = self
        copy.frame = copy.frame.offsetBy(dx: point.x, dy: point.y)
        return copy
    }

    /// Whether the element is visible in the given rect. This takes into account the sticky bounds if the element is sticky.
    /// - Parameter rect: The rect to check visibility in.
    /// - Returns: True if the element is visible in the rect.
    public func isVisible(in rect: CGRect) -> Bool {
        if let extendedStickyBounds = extendedStickyBounds {
            return extendedStickyBounds.intersects(rect)
        }
        return frame.intersects(rect)
    }

}
