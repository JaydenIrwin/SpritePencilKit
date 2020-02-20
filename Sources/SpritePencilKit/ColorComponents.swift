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
    
    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    public static func ==(left: ColorComponents, right: ColorComponents) -> Bool {
        return left.red == right.red && left.green == right.green && left.blue == right.blue && left.alpha == right.alpha
    }
}
