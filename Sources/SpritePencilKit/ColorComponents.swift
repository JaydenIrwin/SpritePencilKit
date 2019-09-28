//
//  ColorComponents.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2019-06-06.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import Foundation

public struct ColorComponents: Equatable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
    
    static func ==(left: ColorComponents, right: ColorComponents) -> Bool {
        return left.red == right.red && left.green == right.green && left.blue == right.blue && left.alpha == right.alpha
    }
}
