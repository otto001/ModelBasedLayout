//
//  ChunkedRectMap.swift
//  
//
//  Created by Matteo Ludwig on 01.09.23.
//

import Foundation


class ChunkedRectMap<Value> {
    struct ChunkId: Hashable, Equatable, Comparable {
        static func < (lhs: ChunkedRectMap.ChunkId, rhs: ChunkedRectMap.ChunkId) -> Bool {
            lhs.row < rhs.row || (lhs.row == rhs.row && lhs.col < rhs.col)
        }
        
        var row: Int
        var col: Int
    }
    
    class Entry {
        let value: Value
        let rect: CGRect
        
        init(value: Value, rect: CGRect) {
            self.value = value
            self.rect = rect
        }
    }
    
    let chunkSize: CGSize
    private var data: [ChunkId: [Entry]] = [:]
    private(set) var count: Int = 0
    
    init(chunkSize: CGSize) {
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
    
    private func insert(_ entry: Entry, into chunkId: ChunkId) {
        data[chunkId, default: []].append(entry)
    }
    
    func insert(_ value: Value, with rect: CGRect) {
        let entry = Entry(value: value, rect: rect)
        let chunkIds = chunkIds(for: rect)
        for chunkId in chunkIds {
            insert(entry, into: chunkId)
        }
        count += 1
    }
    
    func query(_ rect: CGRect) -> [Value] {
        var results: [Value] = []
        let chunkIds = chunkIds(for: rect)
        for chunkId in chunkIds {
            if let entries = data[chunkId] {
                results.append(contentsOf: entries.filter { $0.rect.intersects(rect) }.map { $0.value })
            }
        }
        
        return results
    }
    
    func removeAll(keepingCapacity: Bool = false) {
        self.data.removeAll(keepingCapacity: keepingCapacity)
        self.count = 0
    }
}
