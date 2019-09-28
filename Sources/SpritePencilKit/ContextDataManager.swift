//
//  ContextDataSnapshot.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2019-07-29.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import CoreGraphics

public struct ContextDataManager {
    
    static public let contextWidthMultiple = 8
    
    public var rowOffset: Int
    public var dataPointer: UnsafeMutablePointer<UInt8>
    
    public func dataOffset(for point: PixelPoint) -> Int {
        return 4 * ((point.y * rowOffset) + point.x)
    }
    
}
