//
//  LayoutContainer.swift
//  
//
//  Created by Matteo Ludwig on 31.08.23.
//

import Foundation


class LayoutContainer<ModelType: LayoutModel> {
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
    
    private var cachedLayout: Layout?
    
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
        self.cachedLayout = nil
    }
    
    func makeNewLayout(forNewBounds newBounds: CGRect? = nil) -> Layout {
        let dataSourceCounts = dataSourceCountsProvider()
        var geometryInfo = geometryInfoProvider()
        
        if let newBounds = newBounds {
            geometryInfo.viewSize = newBounds.size
        }
        
        if let cachedLayout = self.cachedLayout,
           cachedLayout.geometryInfo == geometryInfo,
           cachedLayout.dataSourceCounts == dataSourceCounts {
            // We need to make sure to invalidate the stickyControllers cached bounds since they may be outdated
            cachedLayout.stickyController.invalidateVisibleBounds()
            return cachedLayout
        }
        
        let model = modelProvider(dataSourceCounts, geometryInfo)
        let stickyController = StickyController(dataSourceCounts: dataSourceCounts,
                                                geometryInfo: geometryInfo,
                                                boundsProvider: self.boundsProvider) { (elementKind: ElementKind, indexPair: IndexPair) in
            switch elementKind {
            case .header:
                return model.layoutAttributes(forHeaderOfSection: indexPair.section)
            case .footer:
                return model.layoutAttributes(forFooterOfSection: indexPair.section)
            case .additionalSupplementaryView(let elementKind):
                return model.layoutAttributes(forAdditionalSupplementaryViewOfKind: elementKind, at: indexPair)
            default:
                return nil
            }
        }
        
        self.cachedLayout = Layout(geometryInfo: geometryInfo,
                                   dataSourceCounts: dataSourceCounts,
                                   stickyController: stickyController,
                                   model: model)
        
        return self.cachedLayout!
    }
    
    func clearLayoutBefore() {
        self.layoutBeforeUpdate = nil
    }
}
