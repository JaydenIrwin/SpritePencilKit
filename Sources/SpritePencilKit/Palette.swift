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
        case sp16 = "SP 16"
    }
    
    public static let rrggbb = Palette(name: "RRGGBB", special: .rrggbb, colors: {
        var colors = [ColorComponents]()
        for red in 0..<4 {
                for green in 0..<4 {
                    for blue in 0..<4 {
                        colors.append(ColorComponents(red: UInt8(red)*(255/3), green: UInt8(green)*(255/3), blue: UInt8(blue)*(255/3), alpha: 255))
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
        return colors.map({ color in
            var red: CGFloat = 0.0
            var green: CGFloat = 0.0
            var blue: CGFloat = 0.0
            var alpha: CGFloat = 0.0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return ColorComponents(red: UInt8(red*255), green: UInt8(green*255), blue: UInt8(blue*255), alpha: 255)
        })
    }())
    public static let rrrgggbb = Palette(name: "RRRGGGBB", special: .rrrgggbb, colors: {
        var colors = [ColorComponents]()
        for red in 0..<8 {
                for green in 0..<8 {
                    for blue in 0..<4 {
                        colors.append(ColorComponents(red: UInt8(red)*(255/7), green: UInt8(green)*(255/7), blue: UInt8(blue)*(255/3), alpha: 255))
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
    public static let endesga32 = Palette(name: "ENDESGA 32", special: nil, colors: {
        let rgb: [(r: UInt8, g: UInt8, b: UInt8)] = [(190, 74, 47),(215, 118, 67),(234, 212, 170),(228, 166, 114),(184, 111, 80),(115, 62, 57),(62, 39, 49),(162, 38, 51),(228, 59, 68),(247, 118, 34),(254, 174, 52),(254, 231, 97),(99, 199, 77),(62, 137, 72),(38, 92, 66),(25, 60, 62),(18, 78, 137),(0, 153, 219),(44, 232, 245),(255, 255, 255),(192, 203, 220),(139, 155, 180),(90, 105, 136),(58, 68, 102),(38, 43, 68),(24, 20, 37),(255, 0, 68),(104, 56, 108),(181, 80, 136),(246, 117, 122),(232, 183, 150),(194, 133, 105)]
        return rgb.map({ ColorComponents(red: $0.r, green: $0.g, blue: $0.b, alpha: 255) })
    }())
    public static let endesga64 = Palette(name: "ENDESGA 64", special: nil, colors: {
        let rgb: [(r: UInt8, g: UInt8, b: UInt8)] = [(255, 0, 64),(19, 19, 19),(27, 27, 27),(39, 39, 39),(61, 61, 61),(93, 93, 93),(133, 133, 133),(180, 180, 180),(255, 255, 255),(199, 207, 221),(146, 161, 185),(101, 115, 146),(66, 76, 110),(42, 47, 78),(26, 25, 50),(14, 7, 27),(28, 18, 28),(57, 31, 33),(93, 44, 40),(138, 72, 54),(191, 111, 74),(230, 156, 105),(246, 202, 159),(249, 230, 207),(237, 171, 80),(224, 116, 56),(198, 69, 36),(142, 37, 29),(255, 80, 0),(237, 118, 20),(255, 162, 20),(255, 200, 37),(255, 235, 87),(211, 252, 126),(153, 230, 95),(90, 197, 79),(51, 152, 75),(30, 111, 80),(19, 76, 76),(12, 46, 68),(0, 57, 109),(0, 105, 170),(0, 152, 220),(0, 205, 249),(12, 241, 255),(148, 253, 255),(253, 210, 237),(243, 137, 245),(219, 63, 253),(122, 9, 250),(48, 3, 217),(12, 2, 147),(3, 25, 63),(59, 20, 67),(98, 36, 97),(147, 56, 143),(202, 82, 201),(200, 80, 134),(246, 129, 135),(245, 85, 93),(234, 50, 60),(196, 36, 48),(137, 30, 43),(87, 28, 3)]
        return rgb.map({ ColorComponents(red: $0.r, green: $0.g, blue: $0.b, alpha: 255) })
    }())
    public static let zughy32 = Palette(name: "Zughy 32", special: nil, colors: {
        let rgb: [(r: UInt8, g: UInt8, b: UInt8)] = [(71, 45, 60),(94, 54, 67),(122, 68, 74),(160, 91, 83),(191, 121, 88),(238, 161, 96),(244, 204, 161),(182, 213, 60),(113, 170, 52),(57, 123, 68),(60, 89, 86),(48, 44, 46),(90, 83, 83),(125, 112, 113),(160, 147, 142),(207, 198, 184),(223, 246, 245),(138, 235, 241),(40, 204, 223),(57, 120, 168),(57, 71, 120),(57, 49, 75),(86, 64, 100),(142, 71, 140),(205, 96, 147),(255, 174, 182),(244, 180, 27),(244, 126, 27),(230, 72, 46),(169, 59, 59),(130, 112, 148),(79, 84, 107)]
        return rgb.map({ ColorComponents(red: $0.r, green: $0.g, blue: $0.b, alpha: 255) })
    }())
    public static let sp16 = Palette(name: "SP 16", special: .sp16, colors: {
        let rgb: [(r: UInt8, g: UInt8, b: UInt8)] = [
            (255, 255, 255),(170, 170, 170),(85, 85, 85),(0, 0, 0),
            (178, 36, 25),(255, 51, 41),(255, 148, 0),(255, 204, 0),
            (56, 161, 61),(76, 217, 99),(75, 190, 255),(20, 122, 245),
            (89, 87, 214),(255, 107, 188),(230, 185, 140),(140, 90, 40)
        ]
        return rgb.map({ ColorComponents(red: $0.r, green: $0.g, blue: $0.b, alpha: 255) })
    }())
    public static let sweetie16 = Palette(name: "Sweetie 16", special: nil, colors: {
        let rgb: [(r: UInt8, g: UInt8, b: UInt8)] = [(26, 28, 44),(93, 39, 93),(177, 62, 83),(239, 125, 87),(255, 205, 117),(167, 240, 112),(56, 183, 100),(37, 113, 121),(41, 54, 111),(59, 93, 201),(65, 166, 246),(115, 239, 247),(244, 244, 244),(148, 176, 194),(86, 108, 134),(51, 60, 87)]
        return rgb.map({ ColorComponents(red: $0.r, green: $0.g, blue: $0.b, alpha: 255) })
    }())
    public static let bricks = Palette(name: "Bricks", special: nil, colors: {
        let rgb: [(r: UInt8, g: UInt8, b: UInt8)] = [
            (242,243,242),(230,227,224),(160,165,169),(99,95,97),(5,19,29),(242,205,55),(201,26,9),(114,14,15),
            (180,210,227),(90,147,219),(0,85,191),(10,52,99),(75,159,74),(35,120,65),(24,70,50),(88,42,18),
            (53,33,0),(7,139,201),(169,85,0),(149,138,115),(125,191,221),(250,156,28),(208,145,104),(224,255,176),
            (187,233,11),(246,215,179),(194,218,184),(249,186,97),(254,186,189),(201,202,226),(146,57,120),(204,112,42),
            (115,220,161),(63,54,145),(199,210,60),(255,167,11),(254,138,24),(242,112,94),(96,116,161),(160,188,172),
            (132,94,132),(228,205,158),(0,143,155),(67,84,163)
        ]
        return rgb.map({ ColorComponents(red: $0.r, green: $0.g, blue: $0.b, alpha: 255) })
    }())
    public static let rct = Palette(name: "RCT", special: nil, colors: {
        let rgb: [(r: UInt8, g: UInt8, b: UInt8)] = [(0, 0, 0),(23, 35, 35),(35, 51, 51),(47, 67, 67),(63, 83, 83),(75, 99, 99),(91, 115, 115),(111, 131, 131),(131, 151, 151),(159, 175, 175),(183, 195, 195),(211, 219, 219),(239, 243, 243),(51, 47, 0),(63, 59, 0),(79, 75, 11),(91, 91, 19),(107, 107, 31),(119, 123, 47),(135, 139, 59),(151, 155, 79),(167, 175, 95),(187, 191, 115),(203, 207, 139),(223, 227, 163),(67, 43, 7),(87, 59, 11),(111, 75, 23),(127, 87, 31),(143, 99, 39),(159, 115, 51),(179, 131, 67),(191, 151, 87),(203, 175, 111),(219, 199, 135),(231, 219, 163),(247, 239, 195),(71, 27, 0),(95, 43, 0),(119, 63, 0),(143, 83, 7),(167, 111, 7),(191, 139, 15),(215, 167, 19),(243, 203, 27),(255, 231, 47),(255, 243, 95),(255, 251, 143),(255, 255, 195),(35, 0, 0),(79, 0, 0),(95, 7, 7),(111, 15, 15),(127, 27, 27),(143, 39, 39),(163, 59, 59),(179, 79, 79),(199, 103, 103),(215, 127, 127),(235, 159, 159),(255, 191, 191),(27, 51, 19),(35, 63, 23),(47, 79, 31),(59, 95, 39),(71, 111, 43),(87, 127, 51),(99, 143, 59),(115, 155, 67),(131, 171, 75),(147, 187, 83),(163, 203, 95),(183, 219, 103),(31, 55, 27),(47, 71, 35),(59, 83, 43),(75, 99, 55),(91, 111, 67),(111, 135, 79),(135, 159, 95),(159, 183, 111),(183, 207, 127),(195, 219, 147),(207, 231, 167),(223, 247, 191),(15, 63, 0),(19, 83, 0),(23, 103, 0),(31, 123, 0),(39, 143, 7),(55, 159, 23),(71, 175, 39),(91, 191, 63),(111, 207, 87),(139, 223, 115),(163, 239, 143),(195, 255, 179),(79, 43, 19),(99, 55, 27),(119, 71, 43),(139, 87, 59),(167, 99, 67),(187, 115, 83),(207, 131, 99),(215, 151, 115),(227, 171, 131),(239, 191, 151),(247, 207, 171),(255, 227, 195),(15, 19, 55),(39, 43, 87),(51, 55, 103),(63, 67, 119),(83, 83, 139),(99, 99, 155),(119, 119, 175),(139, 139, 191),(159, 159, 207),(183, 183, 223),(211, 211, 239),(239, 239, 255),(0, 27, 111),(0, 39, 151),(7, 51, 167),(15, 67, 187),(27, 83, 203),(43, 103, 223),(67, 135, 227),(91, 163, 231),(119, 187, 239),(143, 211, 243),(175, 231, 251),(215, 247, 255),(11, 43, 15),(15, 55, 23),(23, 71, 31),(35, 83, 43),(47, 99, 59),(59, 115, 75),(79, 135, 95),(99, 155, 119),(123, 175, 139),(147, 199, 167),(175, 219, 195),(207, 243, 223),(63, 0, 95),(75, 7, 115),(83, 15, 127),(95, 31, 143),(107, 43, 155),(123, 63, 171),(135, 83, 187),(155, 103, 199),(171, 127, 215),(191, 155, 231),(215, 195, 243),(243, 235, 255),(63, 0, 0),(87, 0, 0),(115, 0, 0),(143, 0, 0),(171, 0, 0),(199, 0, 0),(227, 7, 0),(255, 7, 0),(255, 79, 67),(255, 123, 115),(255, 171, 163),(255, 219, 215),(79, 39, 0),(111, 51, 0),(147, 63, 0),(183, 71, 0),(219, 79, 0),(255, 83, 0),(255, 111, 23),(255, 139, 51),(255, 163, 79),(255, 183, 107),(255, 203, 135),(255, 219, 163),(0, 51, 47),(0, 63, 55),(0, 75, 67),(0, 87, 79),(7, 107, 99),(23, 127, 119),(43, 147, 143),(71, 167, 163),(99, 187, 187),(131, 207, 207),(171, 231, 231),(207, 255, 255),(63, 0, 27),(91, 0, 39),(119, 0, 59),(147, 7, 75),(179, 11, 99),(199, 31, 119),(219, 59, 143),(239, 91, 171),(243, 119, 187),(247, 151, 203),(251, 183, 223),(255, 215, 239),(39, 19, 0),(55, 31, 7),(71, 47, 15),(91, 63, 31),(107, 83, 51),(123, 103, 75),(143, 127, 107),(163, 147, 127),(187, 171, 147),(207, 195, 171),(231, 219, 195),(255, 243, 223),(255, 183, 0),(255, 219, 0),(255, 255, 0),(0, 0, 99),(27, 43, 139),(39, 59, 151)]
        return rgb.map({ ColorComponents(red: $0.r, green: $0.g, blue: $0.b, alpha: 255) })
    }())
    
    public static var customPalettes = [Palette]()
    public static var palettes: [Palette] {
        return [Palette.rrggbb, Palette.hhhhssbb, Palette.rrrgggbb, Palette.endesga32, Palette.endesga64, Palette.zughy32, Palette.sp16, Palette.sweetie16, Palette.bricks, Palette.rct] + customPalettes
    }
    public static var defaultPalette = Palette.endesga64
    
    public static func ==(_ lhs: Palette, _ rhs: Palette) -> Bool {
        return lhs.name == rhs.name
    }
    
    public let name: String
    public let special: Special?
    public let colors: [ColorComponents]
    
    public func highlight(forColorComponents components: ColorComponents) -> ColorComponents {
        switch special {
        case .rrggbb:
            // Increase components with value = 0 if nothing else can be increased
            let increaseZeros = (components.red == 0 || components.red == 255)
                && (components.green == 0 || components.green == 255)
                && (components.blue == 0 || components.blue == 255)
            
            let red: UInt8 = {
                if components.red == 0 {
                    return increaseZeros ? 255/3 : 0
                } else if 255 - components.red < 255/3 {
                    return 255
                } else {
                    return components.red + 255/3
                }
            }()
            let green: UInt8 = {
                if components.green == 0 {
                    return increaseZeros ? 255/3 : 0
                } else if 255 - components.green < 255/3 {
                    return 255
                } else {
                    return components.green + 255/3
                }
            }()
            let blue: UInt8 = {
                if components.blue == 0 {
                    return increaseZeros ? 255/3 : 0
                } else if 255 - components.blue < 255/3 {
                    return 255
                } else {
                    return components.blue + 255/3
                }
            }()
            return ColorComponents(red: red, green: green, blue: blue, alpha: components.alpha)
        case .rrrgggbb:
            // Increase components with value = 0 if nothing else can be increased
            let increaseZeros = (components.red == 0 || components.red == 255)
                && (components.green == 0 || components.green == 255)
                && (components.blue == 0 || components.blue == 255)
            
            let red: UInt8 = {
                if components.red == 0 {
                    return increaseZeros ? 255/7 : 0
                } else if 255 - components.red < 255/7 {
                    return 255
                } else {
                    return components.red + 255/7
                }
            }()
            let green: UInt8 = {
                if components.green == 0 {
                    return increaseZeros ? 255/7 : 0
                } else if 255 - components.green < 255/7 {
                    return 255
                } else {
                    return components.green + 255/7
                }
            }()
            let blue: UInt8 = {
                if components.blue == 0 {
                    return increaseZeros ? 255/3 : 0
                } else if 255 - components.blue < 255/3 {
                    return 255
                } else {
                    return components.blue + 255/3
                }
            }()
            return ColorComponents(red: red, green: green, blue: blue, alpha: components.alpha)
        default:
            let color = UIColor(components: components)
            var hue: CGFloat = 0.0
            var saturation: CGFloat = 0.0
            var brightness: CGFloat = 0.0
            var alpha: CGFloat = 1.0
            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            if brightness < 1.0 {
                brightness = min(brightness + 0.33333, 1.0)
            } else {
                saturation = max(0.0, saturation - 0.33333)
            }
            let newColor = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
            var red: CGFloat = 0.0
            var green: CGFloat = 0.0
            var blue: CGFloat = 0.0
            newColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return ColorComponents(red: UInt8(red*255), green: UInt8(green*255), blue: UInt8(blue*255), alpha: components.alpha)
        }
    }
    
    public func shadow(forColorComponents components: ColorComponents) -> ColorComponents {
        switch special {
        case .rrggbb:
            let red: UInt8 = {
                if components.red < 255/3 {
                    return 0
                } else {
                    return components.red - 255/3
                }
            }()
            let green: UInt8 = {
                if components.green < 255/3 {
                    return 0
                } else {
                    return components.green - 255/3
                }
            }()
            let blue: UInt8 = {
                if components.blue < 255/3 {
                    return 0
                } else {
                    return components.blue - 255/3
                }
            }()
            return ColorComponents(red: red, green: green, blue: blue, alpha: components.alpha)
        case .rrrgggbb:
            let red: UInt8 = {
                if components.red < 255/7 {
                    return 0
                } else {
                    return components.red - 255/7
                }
            }()
            let green: UInt8 = {
                if components.green < 255/7 {
                    return 0
                } else {
                    return components.green - 255/7
                }
            }()
            let blue: UInt8 = {
                if components.blue < 255/3 {
                    return 0
                } else {
                    return components.blue - 255/3
                }
            }()
            return ColorComponents(red: red, green: green, blue: blue, alpha: components.alpha)
        default:
            let color = UIColor(components: components)
            var hue: CGFloat = 0.0
            var saturation: CGFloat = 0.0
            var brightness: CGFloat = 0.0
            var alpha: CGFloat = 1.0
            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            let newColor = UIColor(hue: hue, saturation: saturation, brightness: max(0.0, brightness - 0.33333), alpha: alpha)
            var red: CGFloat = 0.0
            var green: CGFloat = 0.0
            var blue: CGFloat = 0.0
            newColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return ColorComponents(red: UInt8(red*255), green: UInt8(green*255), blue: UInt8(blue*255), alpha: components.alpha)
        }
    }
    
}
