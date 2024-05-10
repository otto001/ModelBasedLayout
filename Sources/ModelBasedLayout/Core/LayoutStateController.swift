//
//  LayoutStateController.swift
//  
//
//  Created by Matteo Ludwig on 31.08.23.
//

import Foundation


class LayoutStateController<ModelType: LayoutModel> {
    
    
    private(set) var modelProvider: (_ dataSourceCounts: DataSourceCounts, _ geometryInfo: GeometryInfo) -> ModelType
    private(set) var dataSourceCountsProvider: () -> DataSourceCounts
    private(set) var geometryInfoProvider: () -> GeometryInfo
    private(set) var boundsInfoProvider: () -> BoundsInfo
    
    private var layoutAfterUpdate: LayoutContainer<ModelType>?
    private var layoutBeforeUpdate: LayoutContainer<ModelType>?
    private var layoutBeforeUpdatePass: UInt64 = 0
    private var canOverwriteLayoutBeforeUpdate: Bool = true
    
    private var cachedLayout: LayoutContainer<ModelType>?
    
    private var layoutPass: UInt64 = 0
    
    var isTransitioning: Bool {
        self.layoutBeforeUpdate != nil
    }
    
    init(modelProvider: @escaping (_: DataSourceCounts, _: GeometryInfo) -> ModelType,
         dataSourceCountsProvider: @escaping () -> DataSourceCounts,
         geometryInfoProvider: @escaping () -> GeometryInfo,
         boundsInfoProvider: @escaping () -> BoundsInfo) {
        
        self.modelProvider = modelProvider
        self.dataSourceCountsProvider = dataSourceCountsProvider
        self.geometryInfoProvider = geometryInfoProvider
        self.boundsInfoProvider = boundsInfoProvider
    }
    
    func layout(_ state: LayoutState) -> LayoutContainer<ModelType>? {
        switch state {
        case .beforeUpdate:
            return layoutBeforeUpdate
        case .afterUpdate:
            return layoutAfterUpdate
        }
    }
    
    func prepare() {
        
        // Clear layoutBeforeUpdate if it is stale
        if self.canOverwriteLayoutBeforeUpdate && self.layoutBeforeUpdate != nil && self.layoutPass - self.layoutBeforeUpdatePass > 1 {
            self.layoutBeforeUpdate = nil
        }
        
        self.canOverwriteLayoutBeforeUpdate = true
        
    }
    
    func pushNewLayout() {
        if self.canOverwriteLayoutBeforeUpdate {
            self.layoutBeforeUpdate = self.layoutAfterUpdate
            self.layoutBeforeUpdatePass = self.layoutPass
        }
        
        
        self.layoutPass &+= 1
        
        self.layoutAfterUpdate = self.makeNewLayout()
        self.cachedLayout = nil
    }
    
    func makeNewLayout(forNewBounds newBounds: CGRect? = nil) -> LayoutContainer<ModelType>? {
        let dataSourceCounts = dataSourceCountsProvider()
        var geometryInfo = geometryInfoProvider()
        
        if let newBounds = newBounds {
            geometryInfo.viewSize = newBounds.size
        }
        
        if geometryInfo.viewSize.width == 0 || geometryInfo.viewSize.height == 0 {
            return nil
        }
        
        if let cachedLayout = self.cachedLayout,
           cachedLayout.geometryInfo == geometryInfo,
           cachedLayout.dataSourceCounts == dataSourceCounts {
            // We need to make sure to invalidate the stickyControllers cached bounds since they may be outdated
            cachedLayout.boundsController.invalidate()
            return cachedLayout
        }
        
        let model = modelProvider(dataSourceCounts, geometryInfo)
        
        let boundsController = BoundsController(boundsInfoProvider: self.boundsInfoProvider, viewSize: geometryInfo.viewSize)

        let stickyController = StickyController(boundsController: boundsController) { element in
            model.layoutAttributes(for: element)
        }
        
        self.cachedLayout = LayoutContainer(geometryInfo: geometryInfo,
                                            dataSourceCounts: dataSourceCounts,
                                            stickyController: stickyController,
                                            boundsController: boundsController,
                                            model: model)
        
        return self.cachedLayout!
    }
    
    func clearLayoutBefore() {
        self.layoutBeforeUpdate = nil
    }
}
