//
//  LayoutContainer.swift
//  
//
//  Created by Matteo Ludwig on 13.09.23.
//

import Foundation


struct LayoutContainer<ModelType: LayoutModel> {
    let geometryInfo: GeometryInfo
    let dataSourceCounts: DataSourceCounts
    let stickyController: StickyController
    let boundsController: BoundsController
    var model: ModelType
}
