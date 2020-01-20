//
//  Palette.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2018-10-01.
//  Copyright © 2018 Jayden Irwin. All rights reserved.
//

import UIKit

public struct Palette: Equatable {
    
    public enum Special: String, CaseIterable {
        case rrggbb = "RRGGBB"
        case hhhhssbb = "HHHHSSBB"
        case rrrgggbb = "RRRGGGBB"
        case messages = "Messages"
    }
    
    public static let messages = Palette(name: "Messages", special: .messages, colors: {
        var colors = [UIColor]()
        for brightness in 0..<4 {
            colors.append(UIColor(hue: 1.0, saturation: 0.0, brightness: 1.0-(CGFloat(brightness)/3), alpha: 1.0))
        }
        colors += [
            UIColor(red: 0.7, green: 0.14, blue: 0.1, alpha: 1.0),
            UIColor(red: 1.0, green: 0.20, blue: 0.16, alpha: 1.0), // Red
            UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0),
            UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0),
            UIColor(red: 0.22, green: 0.63, blue: 0.24, alpha: 1.0),
            UIColor(red: 0.3, green: 0.85, blue: 0.39, alpha: 1.0), // Green
            UIColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1.0),
            UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0), // Blue
            UIColor(red: 0.35, green: 0.34, blue: 0.84, alpha: 1.0),
            UIColor(red: 1.0, green: 0.25, blue: 0.40, alpha: 1.0),
            UIColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1.0),
            .brown
        ]
        return colors
    }())
    public static let rrggbb = Palette(name: "RRGGBB", special: .rrggbb, colors: {
        var colors = [UIColor]()
        for red in 0..<4 {
                for green in 0..<4 {
                    for blue in 0..<4 {
                        colors.append(UIColor(red: CGFloat(red)/3.0, green: CGFloat(green)/3.0, blue: CGFloat(blue)/3.0, alpha: 1.0))
                    }
                }
            }
            //        case "RRGGBB - P3":
            //            for red in 0..<4 {
            //                for green in 0..<4 {
            //                    for blue in 0..<4 {
            //                        colors.append(UIColor(displayP3Red: CGFloat(red)/3.0, green: CGFloat(green)/3.0, blue: CGFloat(blue)/3.0, alpha: 1.0))
            //                    }
            //                }
        //            }
        return colors
    }())
    public static let hhhhssbb = Palette(name: "HHHHSSBB", special: .hhhhssbb, colors: {
        var colors = [UIColor]()
        for brightness in stride(from: CGFloat(1.0), to: 0.0, by: -0.33333) {
            colors.append(UIColor(hue: 0.0, saturation: 0.0, brightness: brightness, alpha: 1.0))
        }
        for saturation in stride(from: CGFloat(1.0), to: 0.33333, by: -0.33333) {
            for brightness in stride(from: CGFloat(1.0), to: 0.33333, by: -0.33333) {
                for hue in 0..<16 {
                    colors.append(UIColor(hue: CGFloat(hue)/16.0, saturation: saturation, brightness: brightness, alpha: 1.0))
                }
            }
        }
        return colors
    }())
    public static let rrrgggbb = Palette(name: "RRRGGGBB", special: .rrrgggbb, colors: {
        var colors = [UIColor]()
        for red in 0..<8 {
                for green in 0..<8 {
                    for blue in 0..<4 {
                        colors.append(UIColor(red: CGFloat(red)/7.0, green: CGFloat(green)/7.0, blue: CGFloat(blue)/3.0, alpha: 1.0))
                    }
                }
            }
            //        case "RRRGGGBB - P3":
            //            for red in 0..<8 {
            //                for green in 0..<8 {
            //                    for blue in 0..<4 {
            //                        colors.append(UIColor(displayP3Red: CGFloat(red)/7.0, green: CGFloat(green)/7.0, blue: CGFloat(blue)/3.0, alpha: 1.0))
            //                    }
            //                }
        //            }
        return colors
    }())
    
    public static var customPalettes = [Palette]()
    public static var palettes: [Palette] {
        return [Palette.rrggbb, Palette.hhhhssbb, Palette.rrrgggbb] + customPalettes
    }
    
    public static func ==(_ lhs: Palette, _ rhs: Palette) -> Bool {
        return lhs.name == rhs.name
    }
    
    public let name: String
    public let special: Special?
    public let colors: [UIColor]
    
    public func highlight(forColorComponents colorComponents: ColorComponents) -> UIColor {
        switch special {
        case .rrggbb:
            // Increase components with value = 0 if nothing else can be increased
            let increaseZeros = (colorComponents.red == 0 || colorComponents.red == 255)
                && (colorComponents.green == 0 || colorComponents.green == 255)
                && (colorComponents.blue == 0 || colorComponents.blue == 255)
            
            let red: UInt8 = {
                if colorComponents.red == 0 {
                    return increaseZeros ? 255/3 : 0
                } else if 255 - colorComponents.red < 255/3 {
                    return 255
                } else {
                    return colorComponents.red + 255/3
                }
            }()
            let green: UInt8 = {
                if colorComponents.green == 0 {
                    return increaseZeros ? 255/3 : 0
                } else if 255 - colorComponents.green < 255/3 {
                    return 255
                } else {
                    return colorComponents.green + 255/3
                }
            }()
            let blue: UInt8 = {
                if colorComponents.blue == 0 {
                    return increaseZeros ? 255/3 : 0
                } else if 255 - colorComponents.blue < 255/3 {
                    return 255
                } else {
                    return colorComponents.blue + 255/3
                }
            }()
            let newComponents = ColorComponents(red: red, green: green, blue: blue, alpha: colorComponents.alpha)
            return UIColor(components: newComponents)
        case .rrrgggbb:
            // Increase components with value = 0 if nothing else can be increased
            let increaseZeros = (colorComponents.red == 0 || colorComponents.red == 255)
                && (colorComponents.green == 0 || colorComponents.green == 255)
                && (colorComponents.blue == 0 || colorComponents.blue == 255)
            
            let red: UInt8 = {
                if colorComponents.red == 0 {
                    return increaseZeros ? 255/7 : 0
                } else if 255 - colorComponents.red < 255/7 {
                    return 255
                } else {
                    return colorComponents.red + 255/7
                }
            }()
            let green: UInt8 = {
                if colorComponents.green == 0 {
                    return increaseZeros ? 255/7 : 0
                } else if 255 - colorComponents.green < 255/7 {
                    return 255
                } else {
                    return colorComponents.green + 255/7
                }
            }()
            let blue: UInt8 = {
                if colorComponents.blue == 0 {
                    return increaseZeros ? 255/3 : 0
                } else if 255 - colorComponents.blue < 255/3 {
                    return 255
                } else {
                    return colorComponents.blue + 255/3
                }
            }()
            let newComponents = ColorComponents(red: red, green: green, blue: blue, alpha: colorComponents.alpha)
            return UIColor(components: newComponents)
        default:
            let color = UIColor(components: colorComponents)
            var hue: CGFloat = 0.0
            var saturation: CGFloat = 0.0
            var brightness: CGFloat = 0.0
            var alpha: CGFloat = 1.0
            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            if brightness < 1.0 {
                brightness += 0.33333
            } else {
                saturation -= 0.33333
            }
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
    }
    
    public func shadow(forColorComponents colorComponents: ColorComponents) -> UIColor {
        switch special {
        case .rrggbb:
            let red: UInt8 = {
                if colorComponents.red < 255/3 {
                    return 0
                } else {
                    return colorComponents.red - 255/3
                }
            }()
            let green: UInt8 = {
                if colorComponents.green < 255/3 {
                    return 0
                } else {
                    return colorComponents.green - 255/3
                }
            }()
            let blue: UInt8 = {
                if colorComponents.blue < 255/3 {
                    return 0
                } else {
                    return colorComponents.blue - 255/3
                }
            }()
            let newComponents = ColorComponents(red: red, green: green, blue: blue, alpha: colorComponents.alpha)
            return UIColor(components: newComponents)
        case .rrrgggbb:
            let red: UInt8 = {
                if colorComponents.red < 255/7 {
                    return 0
                } else {
                    return colorComponents.red - 255/7
                }
            }()
            let green: UInt8 = {
                if colorComponents.green < 255/7 {
                    return 0
                } else {
                    return colorComponents.green - 255/7
                }
            }()
            let blue: UInt8 = {
                if colorComponents.blue < 255/3 {
                    return 0
                } else {
                    return colorComponents.blue - 255/3
                }
            }()
            let newComponents = ColorComponents(red: red, green: green, blue: blue, alpha: colorComponents.alpha)
            return UIColor(components: newComponents)
        default:
            let color = UIColor(components: colorComponents)
            var hue: CGFloat = 0.0
            var saturation: CGFloat = 0.0
            var brightness: CGFloat = 0.0
            var alpha: CGFloat = 1.0
            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            return UIColor(hue: hue, saturation: saturation, brightness: brightness - 0.33333, alpha: alpha)
        }
    }
    
}
