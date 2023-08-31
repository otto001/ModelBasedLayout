//
//  LayoutContainer.swift
//  
//
//  Created by Matteo Ludwig on 31.08.23.
//

import Foundation


class LayoutContainer<ModelType: LayoutModel> {
    // MARK: Layout Model & Data
    struct Layout {
        let geometryInfo: GeometryInfo
        let dataSourceCounts: DataSourceCounts
        let stickyController: StickyController
        var model: ModelType
    }
    
    private(set) var modelProvider: (_ dataSourceCounts: DataSourceCounts, _ geometryInfo: GeometryInfo) -> ModelType
    private(set) var dataSourceCountsProvider: () -> DataSourceCounts
    private(set) var geometryInfoProvider: () -> GeometryInfo
    private(set) var boundsProvider: () -> CGRect
    
    private var layoutAfterUpdate: Layout?
    private var layoutBeforeUpdate: Layout?
    
    init(modelProvider: @escaping (_: DataSourceCounts, _: GeometryInfo) -> ModelType,
         dataSourceCountsProvider: @escaping () -> DataSourceCounts,
         geometryInfoProvider: @escaping () -> GeometryInfo,
         boundsProvider: @escaping () -> CGRect) {
        
        self.modelProvider = modelProvider
        self.dataSourceCountsProvider = dataSourceCountsProvider
        self.geometryInfoProvider = geometryInfoProvider
        self.boundsProvider = boundsProvider
    }
    
    func layout(_ state: LayoutState) -> Layout? {
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
    }
    
    func makeNewLayout(forNewBounds newBounds: CGRect? = nil) -> Layout {
        let dataSourceCounts = dataSourceCountsProvider()
        var geometryInfo = geometryInfoProvider()
        
        if let newBounds = newBounds {
            geometryInfo.viewSize = newBounds.size
        }
        
        let model = modelProvider(dataSourceCounts, geometryInfo)
        let stickyController = StickyController(stickyEdges: model.pinSectionHeadersToEdges,
                                                dataSourceCounts: dataSourceCounts,
                                                geometryInfo: geometryInfo,
                                                boundsProvider: self.boundsProvider) { section in
            model.layoutAttributes(forHeaderOfSection: section)
        }
        
        return Layout(geometryInfo: geometryInfo, dataSourceCounts: dataSourceCounts, stickyController: stickyController, model: model)
    }
    
    func clearLayoutBefore() {
        self.layoutBeforeUpdate = nil
    }
}
