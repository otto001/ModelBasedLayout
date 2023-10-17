//
//  ChunkedRectMap.swift
//  
//
//  Created by Matteo Ludwig on 01.09.23.
//

import Foundation


class ChunkedRectMap<Value: Hashable> {
    struct ChunkId: Hashable, Equatable, Comparable {
        static func < (lhs: ChunkedRectMap.ChunkId, rhs: ChunkedRectMap.ChunkId) -> Bool {
            lhs.row < rhs.row || (lhs.row == rhs.row && lhs.col < rhs.col)
        }
        
        var row: Int
        var col: Int
    }
    
    let chunkSize: CGSize
    private var data: [ChunkId: Set<Value>] = [:]
    private var rectsForValues: [Value: CGRect] = [:]
    
    private(set) var count: Int = 0
    
    init(chunkSize: CGSize) {
        assert(chunkSize.width > 0 && chunkSize.height > 0, "Chunksize must be above 0 in both dimensions")
        self.chunkSize = chunkSize
    }
    
    private func chunkId(for point: CGPoint) -> ChunkId {
        let col = point.x / chunkSize.width
        let row = point.y / chunkSize.height
        
        return ChunkId(row: Int(row), col: Int(col))
    }
    
    private func chunkIds(for rect: CGRect) -> [ChunkId] {
        let topLeft = chunkId(for: rect.origin)
        let bottomRight = chunkId(for: CGPoint(x: rect.maxX - 0.0000001, y: rect.maxY - 0.0000001))
        
        var result: [ChunkId] = []
        for row in topLeft.row...bottomRight.row {
            for col in topLeft.col...bottomRight.col {
                result.append(ChunkId(row: row, col: col))
            }
        }
        
        return result
    }
    
    func query(_ rect: CGRect) -> [Value] {
        var results: [Value] = []
        let chunkIds = chunkIds(for: rect)
        for chunkId in chunkIds {
            if let values = data[chunkId] {
                results.append(contentsOf: values.filter {
                    rectsForValues[$0]!.intersects(rect)
                })
            }
        }
        
        return results
    }
    
    private func insert(_ value: Value, into chunkId: ChunkId) {
        data[chunkId, default: Set()].insert(value)
    }
    
    func insert(_ value: Value, with rect: CGRect) {
        let chunkIds = chunkIds(for: rect)
        for chunkId in chunkIds {
            insert(value, into: chunkId)
        }
        rectsForValues[value] = rect
        count += 1
    }
    
    private func remove(_ value: Value, from chunkId: ChunkId) {
        if let index = data[chunkId]?.firstIndex(of: value) {
            data[chunkId]!.remove(at: index)
        }
    }
    
    func remove(value: Value) {
        guard let rect = rectsForValues.removeValue(forKey: value) else { return }
        let chunkIds = chunkIds(for: rect)
        for chunkId in chunkIds {
            remove(value, from: chunkId)
        }
        count -= 1
    }
    
    func removeAll(keepingCapacity: Bool = false) {
        self.data.removeAll(keepingCapacity: keepingCapacity)
        self.count = 0
    }
}
