//
//  Palette.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2018-10-01.
//  Copyright © 2018 Jayden Irwin. All rights reserved.
//

import UIKit

public struct Palette: Equatable {
    
    public static func ==(_ lhs: Palette, _ rhs: Palette) -> Bool {
        return lhs.name == rhs.name
    }
    
    let name: String
    let colors: [UIColor]
    
    init(name: String) {
        self.name = name
        self.colors = {
            var colors = [UIColor]()
            switch name {
            case "Messages":
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
            case "RRGGBB":
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
            case "HHHHSSBB":
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
            case "RRRGGGBB":
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
            default:
                break
            }
            return colors
        }()
    }
    
    func highlight(forColorComponents colorComponents: ColorComponents) -> UIColor {
        switch name {
        case "RRGGBB":
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
        case "RRRGGGBB":
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
    
    func shadow(forColorComponents colorComponents: ColorComponents) -> UIColor {
        switch name {
        case "RRGGBB":
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
        case "RRRGGGBB":
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
