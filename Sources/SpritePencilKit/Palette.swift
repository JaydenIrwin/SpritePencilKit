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
    public static let rct = Palette(name: "RCT", special: nil, colors: {
        let rgb: [(r: CGFloat, g: CGFloat, b: CGFloat)] = [(0, 0, 0),(23, 35, 35),(35, 51, 51),(47, 67, 67),(63, 83, 83),(75, 99, 99),(91, 115, 115),(111, 131, 131),(131, 151, 151),(159, 175, 175),(183, 195, 195),(211, 219, 219),(239, 243, 243),(51, 47, 0),(63, 59, 0),(79, 75, 11),(91, 91, 19),(107, 107, 31),(119, 123, 47),(135, 139, 59),(151, 155, 79),(167, 175, 95),(187, 191, 115),(203, 207, 139),(223, 227, 163),(67, 43, 7),(87, 59, 11),(111, 75, 23),(127, 87, 31),(143, 99, 39),(159, 115, 51),(179, 131, 67),(191, 151, 87),(203, 175, 111),(219, 199, 135),(231, 219, 163),(247, 239, 195),(71, 27, 0),(95, 43, 0),(119, 63, 0),(143, 83, 7),(167, 111, 7),(191, 139, 15),(215, 167, 19),(243, 203, 27),(255, 231, 47),(255, 243, 95),(255, 251, 143),(255, 255, 195),(35, 0, 0),(79, 0, 0),(95, 7, 7),(111, 15, 15),(127, 27, 27),(143, 39, 39),(163, 59, 59),(179, 79, 79),(199, 103, 103),(215, 127, 127),(235, 159, 159),(255, 191, 191),(27, 51, 19),(35, 63, 23),(47, 79, 31),(59, 95, 39),(71, 111, 43),(87, 127, 51),(99, 143, 59),(115, 155, 67),(131, 171, 75),(147, 187, 83),(163, 203, 95),(183, 219, 103),(31, 55, 27),(47, 71, 35),(59, 83, 43),(75, 99, 55),(91, 111, 67),(111, 135, 79),(135, 159, 95),(159, 183, 111),(183, 207, 127),(195, 219, 147),(207, 231, 167),(223, 247, 191),(15, 63, 0),(19, 83, 0),(23, 103, 0),(31, 123, 0),(39, 143, 7),(55, 159, 23),(71, 175, 39),(91, 191, 63),(111, 207, 87),(139, 223, 115),(163, 239, 143),(195, 255, 179),(79, 43, 19),(99, 55, 27),(119, 71, 43),(139, 87, 59),(167, 99, 67),(187, 115, 83),(207, 131, 99),(215, 151, 115),(227, 171, 131),(239, 191, 151),(247, 207, 171),(255, 227, 195),(15, 19, 55),(39, 43, 87),(51, 55, 103),(63, 67, 119),(83, 83, 139),(99, 99, 155),(119, 119, 175),(139, 139, 191),(159, 159, 207),(183, 183, 223),(211, 211, 239),(239, 239, 255),(0, 27, 111),(0, 39, 151),(7, 51, 167),(15, 67, 187),(27, 83, 203),(43, 103, 223),(67, 135, 227),(91, 163, 231),(119, 187, 239),(143, 211, 243),(175, 231, 251),(215, 247, 255),(11, 43, 15),(15, 55, 23),(23, 71, 31),(35, 83, 43),(47, 99, 59),(59, 115, 75),(79, 135, 95),(99, 155, 119),(123, 175, 139),(147, 199, 167),(175, 219, 195),(207, 243, 223),(63, 0, 95),(75, 7, 115),(83, 15, 127),(95, 31, 143),(107, 43, 155),(123, 63, 171),(135, 83, 187),(155, 103, 199),(171, 127, 215),(191, 155, 231),(215, 195, 243),(243, 235, 255),(63, 0, 0),(87, 0, 0),(115, 0, 0),(143, 0, 0),(171, 0, 0),(199, 0, 0),(227, 7, 0),(255, 7, 0),(255, 79, 67),(255, 123, 115),(255, 171, 163),(255, 219, 215),(79, 39, 0),(111, 51, 0),(147, 63, 0),(183, 71, 0),(219, 79, 0),(255, 83, 0),(255, 111, 23),(255, 139, 51),(255, 163, 79),(255, 183, 107),(255, 203, 135),(255, 219, 163),(0, 51, 47),(0, 63, 55),(0, 75, 67),(0, 87, 79),(7, 107, 99),(23, 127, 119),(43, 147, 143),(71, 167, 163),(99, 187, 187),(131, 207, 207),(171, 231, 231),(207, 255, 255),(63, 0, 27),(91, 0, 39),(119, 0, 59),(147, 7, 75),(179, 11, 99),(199, 31, 119),(219, 59, 143),(239, 91, 171),(243, 119, 187),(247, 151, 203),(251, 183, 223),(255, 215, 239),(39, 19, 0),(55, 31, 7),(71, 47, 15),(91, 63, 31),(107, 83, 51),(123, 103, 75),(143, 127, 107),(163, 147, 127),(187, 171, 147),(207, 195, 171),(231, 219, 195),(255, 243, 223),(255, 0, 255),(255, 183, 0),(255, 219, 0),(255, 255, 0),(47, 47, 47),(87, 71, 47),(47, 47, 47),(0, 0, 99),(27, 43, 139),(39, 59, 151)]
        return rgb.map({ UIColor(red: $0.r/255, green: $0.g/255, blue: $0.b/255, alpha: 1) })
    }())
    public static let endesga32 = Palette(name: "ENDESGA 32", special: nil, colors: {
        let rgb: [(r: CGFloat, g: CGFloat, b: CGFloat)] = [(190, 74, 47),(215, 118, 67),(234, 212, 170),(228, 166, 114),(184, 111, 80),(115, 62, 57),(62, 39, 49),(162, 38, 51),(228, 59, 68),(247, 118, 34),(254, 174, 52),(254, 231, 97),(99, 199, 77),(62, 137, 72),(38, 92, 66),(25, 60, 62),(18, 78, 137),(0, 153, 219),(44, 232, 245),(255, 255, 255),(192, 203, 220),(139, 155, 180),(90, 105, 136),(58, 68, 102),(38, 43, 68),(24, 20, 37),(255, 0, 68),(104, 56, 108),(181, 80, 136),(246, 117, 122),(232, 183, 150),(194, 133, 105)]
        return rgb.map({ UIColor(red: $0.r/255, green: $0.g/255, blue: $0.b/255, alpha: 1) })
    }())
    
    public static var customPalettes = [Palette]()
    public static var palettes: [Palette] {
        return [Palette.rrggbb, Palette.hhhhssbb, Palette.rrrgggbb, Palette.rct, Palette.endesga32] + customPalettes
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
