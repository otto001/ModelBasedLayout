//
//  CGPoint+Extensions.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 25.09.22.
//

import Foundation


extension CGPoint {
    static let infinity = CGPoint(x: CGFloat.infinity, y: CGFloat.infinity)
    static let one = CGPoint(x: 1, y: 1)
    
    var cgSize: CGSize {
        return CGSize(width: self.x, height: self.y)
    }
    
    
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func *(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
    }
    
    static func /(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
    }
    
    
    static func *(lhs: CGFloat, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs * rhs.x, y: lhs * rhs.y)
    }
    
    static func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    static func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
    
    static func >(lhs: CGPoint, rhs: CGPoint) -> Bool {
        return lhs.x > rhs.x && lhs.y > rhs.y
    }
    
    static func <(lhs: CGPoint, rhs: CGPoint) -> Bool {
        return lhs.x < rhs.x && lhs.y < rhs.y
    }
    
    static func >=(lhs: CGPoint, rhs: CGPoint) -> Bool {
        return lhs.x >= rhs.x && lhs.y >= rhs.y
    }
    
    static func <=(lhs: CGPoint, rhs: CGPoint) -> Bool {
        return lhs.x <= rhs.x && lhs.y <= rhs.y
    }

}

extension CGSize {
    static let infinity = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
    static let one = CGSize(width: 1, height: 1)
    
    var cgPoint: CGPoint {
        return CGPoint(x: self.width, y: self.height)
    }
    
    static func +(lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    static func -(lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    
    static func *(lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width * rhs.width, height: lhs.height * rhs.height)
    }
    
    static func /(lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width / rhs.width, height: lhs.height / rhs.height)
    }
    
    static func *(lhs: CGFloat, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs * rhs.width, height: lhs * rhs.height)
    }
    
    static func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    
    static func /(lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
    }
    
    static func >(lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width > rhs.width && lhs.height > rhs.height
    }
    
    static func <(lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width < rhs.width && lhs.height < rhs.height
    }
    
    static func >=(lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width >= rhs.width && lhs.height >= rhs.height
    }
    
    static func <=(lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width <= rhs.width && lhs.height <= rhs.height
    }
}


extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
