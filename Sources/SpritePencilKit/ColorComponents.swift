//
//  ColorComponents.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2019-06-06.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import Foundation

public struct ColorComponents: Equatable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
    public let alpha: UInt8
    
    public static func ==(left: ColorComponents, right: ColorComponents) -> Bool {
        return left.red == right.red && left.green == right.green && left.blue == right.blue && left.alpha == right.alpha
    }
}
