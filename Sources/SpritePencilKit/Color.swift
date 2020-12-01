//
//  Color.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2020-11-30.
//

import SwiftUI

extension Color {
    
    init(components: ColorComponents) {
        let red = Double(components.red) / 255.0
        let green = Double(components.green) / 255.0
        let blue = Double(components.blue) / 255.0
        let opacity = Double(components.opacity) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
    
}
