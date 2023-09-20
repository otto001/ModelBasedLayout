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
    private(set) var boundsProvider: () -> CGRect
    
    private var layoutAfterUpdate: LayoutContainer<ModelType>?
    private var layoutBeforeUpdate: LayoutContainer<ModelType>?
    
    private var cachedLayout: LayoutContainer<ModelType>?
    
    var isTransitioning: Bool {
        self.layoutBeforeUpdate != nil
    }
    
    init(modelProvider: @escaping (_: DataSourceCounts, _: GeometryInfo) -> ModelType,
         dataSourceCountsProvider: @escaping () -> DataSourceCounts,
         geometryInfoProvider: @escaping () -> GeometryInfo,
         boundsProvider: @escaping () -> CGRect) {
        
        self.modelProvider = modelProvider
        self.dataSourceCountsProvider = dataSourceCountsProvider
        self.geometryInfoProvider = geometryInfoProvider
        self.boundsProvider = boundsProvider
    }
    
    func layout(_ state: LayoutState) -> LayoutContainer<ModelType>? {
        switch state {
        case .beforeUpdate:
            return layoutBeforeUpdate
        case .afterUpdate:
            return layoutAfterUpdate
        }
    }
    
    
    func pushNewLayout() {
        self.layoutBeforeUpdate = self.layoutAfterUpdate
        self.layoutAfterUpdate = self.makeNewLayout()
        self.cachedLayout = nil
    }
    
    func makeNewLayout(forNewBounds newBounds: CGRect? = nil) -> LayoutContainer<ModelType> {
        let dataSourceCounts = dataSourceCountsProvider()
        var geometryInfo = geometryInfoProvider()
        
        if let newBounds = newBounds {
            geometryInfo.viewSize = newBounds.size
        }
        
        if let cachedLayout = self.cachedLayout,
           cachedLayout.geometryInfo == geometryInfo,
           cachedLayout.dataSourceCounts == dataSourceCounts {
            // We need to make sure to invalidate the stickyControllers cached bounds since they may be outdated
            cachedLayout.boundsController.invalidate()
            return cachedLayout
        }
        
        let model = modelProvider(dataSourceCounts, geometryInfo)
        
        let boundsController = BoundsController(boundsProvider: self.boundsProvider, safeAreaInsets: geometryInfo.safeAreaInsets)
        
        let stickyController = StickyController(dataSourceCounts: dataSourceCounts,
                                                boundsController: boundsController) { element in
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
