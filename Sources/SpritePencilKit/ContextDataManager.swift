//
//  ContextDataSnapshot.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2019-07-29.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import CoreGraphics

public struct ContextDataManager {
    
    static let contextWidthMultiple = 8
    
    var rowOffset: Int
    var dataPointer: UnsafeMutablePointer<UInt8>
    
    func dataOffset(for point: PixelPoint) -> Int {
        return 4 * ((point.y * rowOffset) + point.x)
    }
    
}
