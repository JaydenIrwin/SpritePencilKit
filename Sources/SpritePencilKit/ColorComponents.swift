//
//  ColorComponents.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2019-06-06.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import Foundation

public struct ColorComponents: Equatable {
    
    public static let clear = ColorComponents(red: 0, green: 0, blue: 0, alpha: 0)
    
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
    
    public init?(hex: String) {
        let string: String
        if hex.hasPrefix("#") {
            string = String(hex.dropFirst())
        } else {
            string = hex
        }
        
        let scanner = Scanner(string: string)
        var hexNumber: UInt64 = 0
        
        if string.count == 6 {
            if scanner.scanHexInt64(&hexNumber) {
                red = UInt8((hexNumber & 0xff0000) >> 16)
                green = UInt8((hexNumber & 0x00ff00) >> 8)
                blue = UInt8(hexNumber & 0x0000ff)
                alpha = 255
                return
            }
        } else if string.count == 3 {
            if scanner.scanHexInt64(&hexNumber) {
                red = UInt8((hexNumber & 0xf00) >> 8)
                green = UInt8((hexNumber & 0x0f0) >> 4)
                blue = UInt8(hexNumber & 0x00f)
                alpha = 255
                return
            }
        }
        return nil
    }
    
    public static func ==(left: ColorComponents, right: ColorComponents) -> Bool {
        return left.red == right.red && left.green == right.green && left.blue == right.blue && left.alpha == right.alpha
    }
}
